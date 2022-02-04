//
//  DSSToDoItemCell.swift
//  DSSToDoListApp
//
//  Created by David on 03/02/22.
//

import UIKit

class DSSToDoItemCell: UITableViewCell {
    static var id: String { "\(NSStringFromClass(Self.self)).id" }
    
    var model: DSSToDoListItemModel? {
        didSet {
            textLabel?.text = model?.title
            detailTextLabel?.text = model?.description
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
