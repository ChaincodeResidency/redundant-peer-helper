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
            guard let peer = _selectedPeer else { log(err: PeersViewError.expectedSelectedPeer); break }

            _confirmRemoval(of: peer)
        }
    }
    
    // MARK: - Properties (Mutable)
    
    /** Blockchain data sources
     */
    lazy fileprivate var peers: [BlockchainDataSource] = []
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
        case expectedBalancedTableUpdates
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
    /** Segue to confirm the removal of a peer
    */
    fileprivate func _confirmRemoval(of peer: BlockchainDataSource) {
        let segue: Segue
        
        switch peer.networkType {
        case .redundantPeer:
            segue = .removeRedundantPeer
            
        case .bitcoinNetwork:
            segue = .removeBitcoinNetworkPeer
        }
        
        performSegue(withIdentifier: segue.asIdentifier, sender: self)
    }

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
            
        case .removeBitcoinNetworkPeer, .removeRedundantPeer:
            guard let removePeerViewController = segue.destinationController as? RemovePeerViewController else {
                log(err: PeersViewError.expectedRemovePeerViewController)
                
                break
            }
            
            guard let selectedRow = tableView?.selectedRow, let peer = _peer(atRow: selectedRow) else {
                log(err: PeersViewError.expectedSelectedPeer)
                
                break
            }
            
            removePeerViewController.confirmPeerRemoval = { [weak self] in self?._remove(peer: $0, ban: $1) }
            
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
        case removeBitcoinNetworkPeer = "RemoveBitcoinNetworkPeerSegue"
        
        /** Segue to remove a redundant peer
        */
        case removeRedundantPeer = "RemoveRedundantPeerSegue"
        
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
    /** Remove a peer
    */
    fileprivate func _remove(peer: BlockchainDataSource, ban: Bool) {
        switch peer.networkType {
        case .redundantPeer:
            guard let peer = RedundantPeer(withAddress: peer.address) else {
                log(err: PeersViewError.expectedRedundantPeerToRemove)
                
                break
            }
            
            Configuration.remove(savedRedundantPeer: peer)
            
            tableView?.deselectAll(nil)
            
            updatePeers()
            
        case .bitcoinNetwork:
            guard let ip = IpAddress(withUrlString: peer.address) else {
                log(err: PeersViewError.expectedPeerIp)
                
                break
            }
            
            let duration: TimeInterval? = ban ? LocalCoreService.longestBanInterval : nil
            
            LocalCoreRequest(method: .banPeer(withAddress: ip, duration: duration))?.execute { [weak self] err, _ in
                DispatchQueue.main.async {
                    if let err = err { return log(err: err) }
                    
                    self?.updatePeers()
                }
            }
        }
    }
    
    /** The selected peer
     */
    fileprivate var _selectedPeer: BlockchainDataSource? {
        guard let selectedRow = tableView?.selectedRow, let peer = _peer(atRow: selectedRow) else { return nil }
        
        return peer
    }

    /** Determine the number of rows in the table
     */
    func numberOfRows(in tableView: NSTableView) -> Int {
        return peers.count
    }
    
    /** Table view selection changed
    */
    func tableViewSelectionDidChange(_ notification: Notification) {
        _updateAdjustPeersEnabled()
    }
    
    /** Peers sorted by their connection date
    */
    private static func _connectTimeSorted(peers: [BlockchainDataSource]) -> [BlockchainDataSource] {
        return peers.sorted { $0.connectedSince ?? Date.distantPast < $1.connectedSince ?? Date.distantPast }
    }
    
    /** Modify the peer table view
    */
    private func _modifyPeerList(withNewPeers newPeers: [LocalCoreService.PeerInfo.Peer]) {
        let redundantPeers = Configuration.savedRedundantPeers as [BlockchainDataSource]
        let startingPeers = peers
        
        let startingPeerAddresses = startingPeers.map { $0.address }
        let finalPeers = type(of: self)._connectTimeSorted(peers: redundantPeers + newPeers as [BlockchainDataSource])
        
        let finalPeerAddresses = finalPeers.map { $0.address }
        
        tableView?.beginUpdates()
        
        // For peers in the starting set that aren't in the final set, trigger remove rows
        let removes = Set(startingPeerAddresses)
            .subtracting(Set(finalPeerAddresses))

        // For peers in the final set that aren't in the starting set, trigger add rows
        let inserts = Set(finalPeerAddresses)
            .subtracting(Set(startingPeerAddresses))
        
        guard startingPeers.count - removes.count + inserts.count == finalPeers.count else {
            return log(err: PeersViewError.expectedBalancedTableUpdates)
        }
        
        var startingPeersByAddress = [String: BlockchainDataSource]()
        var finalPeersByAddress = [String: BlockchainDataSource]()
        
        startingPeers.forEach { startingPeersByAddress[$0.address] = $0 }

        finalPeers.forEach { finalPeersByAddress[$0.address] = $0 }

        inserts
            .map { finalPeerAddresses.index(of: $0) }
            .flatMap { $0 }
            .forEach { tableView?.insertRows(at: IndexSet(integer: $0), withAnimation: .slideDown) }

        removes
            .map { startingPeerAddresses.index(of: $0) }
            .flatMap { $0 }
            .forEach { tableView?.removeRows(at: IndexSet(integer: $0), withAnimation: .effectFade) }
        
        // Reload rows where the service has been updated
        let updatedPeers = Set(startingPeerAddresses)
            .subtracting(inserts)
            .subtracting(removes)
            .map { startingPeersByAddress[$0] }
            .flatMap { $0 }
            .filter { startingPeer in
                guard let finalPeer = finalPeersByAddress[startingPeer.address] else { return false }
                
                guard startingPeer.service == finalPeer.service && startingPeer.address == finalPeer.address else {
                    return false
                }

                return true
            }

        let columns = [PeersViewColumn.address, .network, .version]
            .map { tableView?.column(withIdentifier: $0.asColumnIdentifier) }
            .flatMap { $0 }
        
        let columnIndexes = IndexSet(integersIn: (columns.min() ?? Int())...(columns.max() ?? Int()))
        
        updatedPeers
            .map { startingPeerAddresses.index(of: $0.address) }
            .flatMap { $0 }
            .map { return IndexSet(integer: $0) }
            .forEach { tableView?.reloadData(forRowIndexes: $0, columnIndexes: columnIndexes) }
        
        peers = finalPeers

        tableView?.endUpdates()
    }

    /** Update visible peers list
     */
    func updatePeers() {
        LocalCoreService.getPeerInfo { [weak self] peerInfoResponse in
            switch peerInfoResponse {
            case .encounteredError(let err):
                log(err: err)
                
            case .receivedPeerInfo(let peerInfo):
                self?._modifyPeerList(withNewPeers: peerInfo.peers)
            }
        }
    }
}

// MARK: - NSTableViewDelegate
extension PeersViewController: NSTableViewDelegate {
    /** Get a peer for a row #
    */
    fileprivate func _peer(atRow row: Int) -> BlockchainDataSource? {
        guard row >= Int() && row < peers.count else { return nil }
        
        return peers[row]
    }
    
    /** Get service title for peer
     */
    private func _serviceTitle(forPeer peer: BlockchainDataSource) -> String {
        switch peer.networkType {
        case .redundantPeer:
            return "Blockchain Data Service"
            
        case .bitcoinNetwork:
            return "Bitcoin Network"
        }
    }

    /** Table columns
    */
    fileprivate enum PeersViewColumn: String {
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
        
        /** Column identifier
        */
        var asColumnIdentifier: String { return rawValue }
        
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
    fileprivate func _titleForCell(inColumn column: PeersViewColumn, peer: BlockchainDataSource) -> String {
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
            guard let patchVersion = patchVersion else {
                title = "Bitcoin Knots (0." + String(minorVersion) + ")"
                
                break
            }

            title = "Bitcoin Knots (0." + String(minorVersion) + "." + String(patchVersion) + ")"
            
        case (.version, .redundantPeer):
            title = "Redundant Peer Service"

        case (.version, .unidentifiedBitcoinNetworkPeer(let agent)) where agent.isEmpty:
            title = "Connecting..."
            
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
        
        guard let peer = _selectedPeer else { return log(err: PeersViewError.expectedSelectedPeer) }
        
        _confirmRemoval(of: peer)
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
            timeInterval: 0.3,
            target: self,
            selector: #selector(updatePeers),
            userInfo: nil,
            repeats: true
        )
    }
}
