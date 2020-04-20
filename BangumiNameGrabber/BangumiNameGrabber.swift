//
//  BangumiNameGrabber.swift
//  BangumiNameGrabber
//
//  Created by nsfish on 2020/4/20.
//  Copyright © 2020 nsfish. All rights reserved.
//

import Foundation

func seriesNumberRegexFrom(textToFind: String) throws -> NSRegularExpression {
    // 截取剧集集数
    guard let series = textToFind.components(separatedBy: " ").first else {
        throw ParseError.dummy
    }
    // 转换成正则表达式
    let template = "[0-9]{1,3}"
    let numberRegex = try NSRegularExpression.init(pattern: template, options: .caseInsensitive)
    let seriesRegexString = numberRegex.stringByReplacingMatches(in: series,
                                                                 options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                                 range: NSMakeRange(0, series.count),
                                                                 withTemplate: template)
    
    return try NSRegularExpression.init(pattern: seriesRegexString, options: .caseInsensitive)
}
