//
//  main.swift
//  BangumiNameGrabber
//
//  Created by nsfish on 2020/4/20.
//  Copyright © 2020 nsfish. All rights reserved.
//

import Foundation
import SwiftSoup

enum ParseError: Error {
    case dummy
}


if (CommandLine.arguments.count < 5) {
    print("Usage: bangumi-name-parser -url \"url/like/wikipedia/page/of/bangumi\" -f \"001 XXX");
}

var urlString = "", stringToFind = ""
for (index, argument) in CommandLine.arguments.enumerated() {
    if (argument == "-url") {
        urlString = CommandLine.arguments[index + 1]
    }
    else if (argument == "-f") {
        stringToFind = CommandLine.arguments[index + 1]
    }
}

do {
    guard let url = URL.init(string: urlString) else {
        throw ParseError.dummy
    }
    
    let html = try String.init(contentsOf: url)
    let lines = html.split(separator: "\n")
    
    // 先找到指定内容所在行，记录内容行对应的 tag
    guard let stringToFindIndex = lines.firstIndex(where: { $0.contains(stringToFind)}) else {
        throw ParseError.dummy
    }
    let line = String(lines[stringToFindIndex])
    let parsedLine = try SwiftSoup.parse(line)
    guard let node = try parsedLine.getElementsMatchingOwnText(stringToFind).first() else {
        throw ParseError.dummy
    }
    let tag = node.tagName()
    
    // 尝试查找有 id 的 parent 节点所在行，并提取 id
    let linesBefore = lines[0...stringToFindIndex].reversed()
    guard let parentLineWithIDIndex = linesBefore.firstIndex(where: { $0.contains("id=") }) else {
        // 可能没有找到任何带有 id 的节点
        throw ParseError.dummy
    }
    
    // TODO：由于是无视 DOM 结构、单纯地逐行遍历，很可能找到的 id 不是内容节点的父节点
    let parentLineWithID = String(linesBefore[parentLineWithIDIndex])
    let parentID = (parentLineWithID.components(separatedBy: "id=").last ?? "").trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    
    // 解析 DOMs，根据 id 查找父节点，并获取该父节点中所有带文案的子节点
    let doc: Document = try SwiftSoup.parse(html)
    if let body = doc.body() {
        let parentNode = try body.getElementById(parentID)!
        let nodes = try parentNode.getElementsByTag(tag)
        
        var texts = Array<String>()
        try nodes.forEach { node in
            let text = try node.text()
            texts.append(text)
        }
        
        // 构造指定剧集名称对应的正则表达式，用于过滤 texts 中的非剧集文案
        // 比如用户输入"第1集"或"云霄飞车"，则先找到该输入对应的完整剧集名
        guard let textToFind = texts.first(where: { $0.contains(stringToFind) }) else {
            throw ParseError.dummy
        }
        let seriesNumberRegex = try seriesNumberRegexFrom(textToFind: textToFind)
        
        texts = texts.filter { text -> Bool in
            return seriesNumberRegex.numberOfMatches(in: text, options: .anchored, range: NSMakeRange(0, text.count)) > 0
        }
        
        // 保存为 txt
        let result = texts.joined(separator: "\n")
        if let dir = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent("source.txt")
            try result.write(to: fileURL, atomically: false, encoding: .utf8)
        }
    }
} catch Exception.Error( _, let message) {
    print(message)
} catch {
    print("error")
}

