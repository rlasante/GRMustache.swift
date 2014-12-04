//
//  EachFilter.swift
//  GRMustache
//
//  Created by Gwendal Roué on 31/10/2014.
//  Copyright (c) 2014 Gwendal Roué. All rights reserved.
//

class EachFilter: MustacheFilter {
    
    func filterFunction() -> MustacheFilterFunction {
        return { (argument: Box, partialApplication: Bool, error: NSErrorPointer) -> Box? in
            if argument.isEmpty {
                return argument
            } else if let dictionary: [String: Box] = argument.value() {
                return transformedDictionary(dictionary)
            } else if let array: [Box] = argument.value() {
                return transformedSequence(array)
            } else if let set = argument.value() as? NSSet {
                return transformedSet(set)
            } else {
                if error != nil {
                    error.memory = NSError(domain: GRMustacheErrorDomain, code: GRMustacheErrorCodeRenderingError, userInfo: [NSLocalizedDescriptionKey: "filter argument error: not iterable"])
                }
                return nil
            }
        }
    }
    
    private class Item: MustacheCluster, MustacheRenderable {
        let box: Box
        let index: Int
        let last: Bool
        let key: String?
        
        init(box: Box, index: Int, key: String?, last: Bool) {
            self.box = box
            self.index = index
            self.key = key
            self.last = last
        }
        
        var mustacheBool: Bool { return box.mustacheBool }
        var mustacheFilterFunction: MustacheFilterFunction? { return (box.value() as MustacheCluster?)?.mustacheFilterFunction }
        var mustacheInspectable: MustacheInspectable? { return (box.value() as MustacheCluster?)?.mustacheInspectable }
        var mustacheTagObserver: MustacheTagObserver? { return (box.value() as MustacheCluster?)?.mustacheTagObserver }
        var mustacheRenderable: MustacheRenderable? { return self }
        
        func render(var info: RenderingInfo, error: NSErrorPointer) -> Rendering? {
            var position: [String: Box] = [:]
            position["@index"] = Box(index)
            position["@indexPlusOne"] = Box(index + 1)
            position["@indexIsEven"] = Box(index % 2 == 0)
            position["@first"] = Box(index == 0)
            position["@last"] = Box(last)
            if let key = key {
                position["@key"] = Box(key)
            }
            info.context = info.context.extendedContext(box: Box(position))
            return box.render(info, error: error)
        }
    }
}

private func transformedSequence<T: CollectionType where T.Generator.Element == Box, T.Index: Comparable, T.Index.Distance == Int>(collection: T) -> Box {
    var mustacheBoxes: [Box] = []
    let start = collection.startIndex
    let end = collection.endIndex
    var i = start
    while i < end {
        let box = collection[i]
        let index = distance(start, i)
        let last = i.successor() == end
        mustacheBoxes.append(Box(EachFilter.Item(box: box, index: index, key: nil, last: last)))
        i = i.successor()
    }
    return Box(mustacheBoxes)
}

private func transformedSet(set: NSSet) -> Box {
    var mustacheBoxes: [Box] = []
    let count = set.count
    var index = 0
    for item in set {
        let box = Box(item)
        let last = index == count
        mustacheBoxes.append(Box(EachFilter.Item(box: box, index: index, key: nil, last: last)))
        ++index
    }
    return Box(mustacheBoxes)
}

private func transformedDictionary(dictionary: [String: Box]) -> Box {
    var mustacheBoxes: [Box] = []
    let start = dictionary.startIndex
    let end = dictionary.endIndex
    var i = start
    while i < end {
        let (key, box) = dictionary[i]
        let index = distance(start, i)
        let last = i.successor() == end
        mustacheBoxes.append(Box(EachFilter.Item(box: box, index: index, key: key, last: last)))
        i = i.successor()
    }
    return Box(mustacheBoxes)
}

