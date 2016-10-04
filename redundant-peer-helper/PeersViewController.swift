//
//  ViewController.swift
//  redundant-peer-helper
//
//  Created by Alex Bosworth on 9/26/16.
//  Copyright © 2016 Adylitica. All rights reserved.
//

import Cocoa

/** Main view controller
*/
class PeersViewController: NSViewController {
    // MARK: - @IBOutlets
    
    /** Adjust peers list buttons control
    */
    @IBOutlet weak var adjustPeersListButton: NSSegmentedControl?

    /** Image view for bitcoin logo
    */
    @IBOutlet weak var bitcoinLogo: NSImageView?
    
    /** Peers list table view
    */
    @IBOutlet weak var tableView: NSTableView?
    
    // MARK: - @IBActions
    
    /** Pressed an adjust peers list button in adjust peers list segmented control
    */
    @IBAction func pressedAdjustPeersListButton(_ sender: NSSegmentedControl) {
        guard let action = AdjustPeersAction(fromSegmentedControl: sender), sender == adjustPeersListButton else {
            return log(err: PeersViewError.unexpectedSegmentPressed)
        }
        
        sender.setSelected(false, forSegment: sender.selectedSegment)
        
        switch action {
        case .addSyncSource:
            tableView?.deselectAll(nil)
            
            performSegue(withIdentifier: Segue.addSyncSource.asIdentifier, sender: self)

        case .removeSyncSource:
            performSegue(withIdentifier: Segue.removeSyncSource.asIdentifier, sender: self)
        }
    }
    
    // MARK: - Properties (Mutable)
    
    /** Blockchain data sources
     */
    fileprivate var peers: [BlockchainDataSource]?
}

// MARK: - Adjust Peers
extension PeersViewController {
    /** Update adjust peers enabled or disabled
    */
    fileprivate func _updateAdjustPeersEnabled() {
        guard let selectedRow = tableView?.selectedRow else { return log(err: PeersViewError.expectedSelectedRowData) }
        
        adjustPeersListButton?.setEnabled(
            selectedRow != -1,
            forSegment: AdjustPeersAction.removeSyncSource.asSegmentValue
        )
    }
    
    /** Actions that may be taken on a selected block data source
     */
    fileprivate enum AdjustPeersAction: Int {
        case addSyncSource, removeSyncSource
        
        /** Init from a segmented control
         */
        init?(fromSegmentedControl: NSSegmentedControl) {
            guard let action = type(of: self).init(rawValue: fromSegmentedControl.selectedSegment) else { return nil }
            
            self = action
        }
        
        /** Get as segment value
         */
        var asSegmentValue: Int { return rawValue }
    }
}

// MARK: - Errors
extension PeersViewController {
    /** Errors
     */
    enum PeersViewError: Error {
        case expectedAddPeerViewController
        case expectedClickedRow
        case expectedKnownColumn
        case expectedPeerForRow
        case expectedPeerIp
        case expectedRedundantPeerToRemove
        case expectedRemovePeerViewController
        case expectedSelectedPeer
        case expectedSelectedRowData
        case unexpectedSegmentPressed
        case unexpectedSegue
        case unexpectedTableRowActionEdge
    }
}

// MARK: - Navigation
extension PeersViewController {
    /** Prepare to segue to a new view controller
     */
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let segueType = Segue(fromSegue: segue) else { return log(err: PeersViewError.unexpectedSegue) }
        
        switch segueType {
        case .addSyncSource:
            guard let addPeerViewController = segue.destinationController as? AddPeerViewController else {
                log(err: PeersViewError.expectedAddPeerViewController)
                
                break
            }
            
            addPeerViewController.addPeer = { [weak self] redundantPeer in
                Configuration.add(savedRedundantPeer: redundantPeer)
                
                self?.updatePeers()
            }
            
        case .removeSyncSource:
            guard let removePeerViewController = segue.destinationController as? RemovePeerViewController else {
                log(err: PeersViewError.expectedRemovePeerViewController)
                
                break
            }
            
            guard let selectedRow = tableView?.selectedRow, let peer = _peer(atRow: selectedRow) else {
                log(err: PeersViewError.expectedSelectedPeer)
                
                break
            }
            
            removePeerViewController.confirmPeerRemoval = { [weak self] peer in
                switch peer.service.isFromBitcoinNetwork {
                case false:
                    guard let peer = RedundantPeer(withAddress: peer.address) else {
                        log(err: PeersViewError.expectedRedundantPeerToRemove)
                        
                        break
                    }
                    
                    Configuration.remove(savedRedundantPeer: peer)
                    
                    self?.updatePeers()
                    
                case true:
                    guard let ipAddress = IpAddress(withUrlString: peer.address) else {
                        log(err: PeersViewError.expectedPeerIp)
                        
                        break
                    }
                    
                    LocalCoreRequest(method: .banPeer(withAddress: ipAddress, duration: nil))?.execute { err, _ in
                        if let err = err { return log(err: err) }
                        
                        self?.updatePeers()
                    }
                }
            }
            
            removePeerViewController.peer = peer
        }
    }

    /** Peer view Segue
     */
    fileprivate enum Segue: String {
        /** Segue to add a sync source
         */
        case addSyncSource = "AddSyncSourceSegue"
        
        /** Segue to remove a sync source
         */
        case removeSyncSource = "RemoveSyncSourceSegue"
        
        /** Create from storyboard segue
         */
        init?(fromSegue: NSStoryboardSegue) {
            guard let id = fromSegue.identifier, let segue = type(of: self).init(rawValue: id) else { return nil }
            
            self = segue
        }
        
        /** As storyboard identifier
         */
        var asIdentifier: String { return rawValue }
    }
}

// MARK: - NSTableViewDataSource
extension PeersViewController: NSTableViewDataSource {
    /** Determine the number of rows in the table
     */
    func numberOfRows(in tableView: NSTableView) -> Int {
        return peers?.count ?? Int()
    }
    
    /** Table view selection changed
    */
    func tableViewSelectionDidChange(_ notification: Notification) {
        _updateAdjustPeersEnabled()
    }

    /** Update visible peers list
     */
    func updatePeers() {
        let redundantPeers = Configuration.savedRedundantPeers as [BlockchainDataSource]
        
        LocalCoreService.getPeerInfo { [weak self] peerInfoResponse in
            switch peerInfoResponse {
            case .encounteredError(let err):
                log(err: err)
                
            case .receivedPeerInfo(let peerInfo):
                self?.peers = (redundantPeers + peerInfo.peers as [BlockchainDataSource]).sorted { date1, date2 in
                    return date1.connectedSince ?? Date.distantPast < date2.connectedSince ?? Date.distantPast
                }
                
                self?.tableView?.reloadData()
            }
        }
    }
}

// MARK: - NSTableViewDelegate
extension PeersViewController: NSTableViewDelegate {
    /** Get a peer for a row #
    */
    fileprivate func _peer(atRow row: Int) -> BlockchainDataSource? {
        guard let peers = peers, row >= Int() && row < peers.count else { return nil }
        
        return peers[row]
    }
    
    /** Get service title for peer
     */
    private func _serviceTitle(forPeer peer: BlockchainDataSource?) -> String {
        guard let service = peer?.service else { return "Unknown" }

        switch service {
        case .redundantPeer:
            return "Blockchain Data Service"
            
        case _ where service.isFromBitcoinNetwork:
            return "Bitcoin Network"
            
        default:
            return "Unknown Connection"
        }
    }

    /** Table columns
    */
    private enum PeersViewColumn: String {
        case address = "SourceAddressColumn"
        case network = "SourceNetworkColumn"
        case version = "SourceVersionColumn"
        
        /** Create from a table column
        */
        init?(fromTableColumn: NSTableColumn?) {
            guard let id = fromTableColumn?.identifier, let column = type(of: self).init(rawValue: id) else {
                return nil
            }
            
            self = column
        }
        
        /** Cell identifier for column cell
        */
        var asCellIdentifier: String {
            switch self {
            case .address:
                return "SourceAddressCell"
                
            case .network:
                return "SourceNetworkCell"
                
            case .version:
                return "SourceVersionCell"
            }
        }
        
        /** Make a cell in column
        */
        func makeCell(inTableView tableView: NSTableView, withTitle title: String) -> NSTableCellView? {
            let cell = tableView.make(withIdentifier: asCellIdentifier, owner: nil) as? NSTableCellView
            
            cell?.textField?.stringValue = title

            return cell
        }
    }

    /** Determine a title for a cell
    */
    private func _titleForCell(inColumn column: PeersViewColumn, peer: BlockchainDataSource) -> String {
        let title: String
        
        switch (column, peer.service) {
        case (.address, _):
            title = URL(string: peer.address)?.host ?? String()
            
        case (.network, _):
            title = _serviceTitle(forPeer: peer)
            
        case (.version, .bitcoinCore(minorVersion: let minorVersion, patchVersion: let patchVersion)):
            guard let patchVersion = patchVersion else {
                title = "Bitcoin Core (0." + String(minorVersion) + ")"
                
                break
            }
            
            title = "Bitcoin Core (0." + String(minorVersion) + "." + String(patchVersion) + ")"
            
        case (.version, .bitcoinKnots(minorVersion: let minorVersion, patchVersion: let patchVersion)):
            title = "Bitcoin Knots (0." + String(minorVersion) + "." + String(patchVersion) + ")"
            
        case (.version, .redundantPeer):
            title = "Redundant Peer Service"

        case (.version, .unidentifiedBitcoinNetworkPeer(agent: let agent)) where agent.isEmpty:
            title = "Unknown"
            
        case (.version, .unidentifiedBitcoinNetworkPeer(agent: let agent)):
            title = "Unknown (" + agent + ")"
        }
        
        return title
    }
    
    /** Make cell for row at column
    */
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = PeersViewColumn(fromTableColumn: tableColumn) else {
            log(err: PeersViewError.expectedKnownColumn)
            
            return nil
        }
        
        guard let peer = _peer(atRow: row) else {
            log(err: PeersViewError.expectedPeerForRow)
            
            return nil
        }

        let cell = column.makeCell(inTableView: tableView, withTitle: _titleForCell(inColumn: column, peer: peer))
        
        return cell
    }
}

// MARK: - NSMenuDelegate
extension PeersViewController: NSMenuDelegate {
    /** Eliminate a peer
    */
    func removePeerAtClickedRow() {
        guard let clickedPeerAtRow = tableView?.clickedRow else { return log(err: PeersViewError.expectedClickedRow) }
        
        tableView?.selectRowIndexes(IndexSet(integer: clickedPeerAtRow), byExtendingSelection: false)
        
        performSegue(withIdentifier: Segue.removeSyncSource.asIdentifier, sender: self)
    }

    /** Context menu is appearing
    */
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        
        menu.addItem(NSMenuItem(title: "Remove", action: #selector(removePeerAtClickedRow), keyEquivalent: String()))
    }
}

// MARK: - NSViewController
extension PeersViewController {
    /** View loaded
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView?.menu = NSMenu()
        
        tableView?.menu?.delegate = self
        
        updatePeers()
        
        Timer.scheduledTimer(
            timeInterval: 10, // FIXME: - reduce, abstract, temporarily set high due to row selection loss issue
            target: self,
            selector: #selector(updatePeers),
            userInfo: nil,
            repeats: true
        )
    }
}
