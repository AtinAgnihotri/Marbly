//
//  GameScene.swift
//  Marbly
//
//  Created by Atin Agnihotri on 27/08/21.
//

import SpriteKit
import CoreMotion

enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
    case teleport = 32
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let TOUCH_FACTOR: CGFloat = 1/100
    let ACCELEROMETER_FACTOR: Double = 50
    let ANIMATION_DURATION: TimeInterval = 0.25
    
    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var lastTouchPosition: CGPoint?
    
    var motionManager: CMMotionManager?
    var teleportEntry: SKSpriteNode!
    var teleportExit: SKSpriteNode!
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var playerMovable = true {
        didSet {
            player.physicsBody?.isDynamic = playerMovable
        }
    }
    var isGameOver = false {
        didSet {
            if isGameOver {
                playerMovable = false
                gameOver()
            }
        }
    }
    
    override func didMove(to view: SKView) {
        addScoreLabel()
        loadLevel(1)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if !isGameOver {
            #if targetEnvironment(simulator)
            setGravityToLastTouch()
            #else
            setGravityToAccelerometerData()
            #endif
        }
    }
    
    func addScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
        
        score = 0
    }
    
    func loadLevel(_ level: Int) {
        addBackground()
        
        let levelData = loadLevelFile(level)

        addElements(for: levelData)
        
        // todo: Make Player Loc Dynamic
        addPlayer(at: CGPoint(x: 96, y: 672))
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        if motionManager == nil {
            motionManager = CMMotionManager()
        }
        motionManager?.startAccelerometerUpdates()
    }
    
    func loadLevelFile(_ level: Int) -> String {
        if let url = Bundle.main.url(forResource: "level\(level)", withExtension: "txt") {
            if let level = try? String(contentsOf: url) {
                return level
            }
        }
        fatalError("Failed to load level from disk")
    }
    
    func addBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.zPosition = -1
        background.blendMode = .replace
        addChild(background)
    }
    
    func addElements(for levelData: String) {
        let levelLine = levelData.components(separatedBy: "\n")
        
        for (row, line) in levelLine.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = getTilePosition(row: row, column: column)
                addElement(for: letter, at: position)
            }
        }
    }
    
    func addElement(for letter: String.Element, at location: CGPoint) {
        switch letter {
        case "x":
            addWall(at: location)
        case "v":
            addVortex(at: location)
        case "f":
            addFinishTile(at: location)
        case "s":
            addStar(at: location)
        case "1":
            addTeleportEntry(at: location)
        case "2":
            addTeleportExit(at: location)
        case " ":
           return
        default:
            fatalError("Unknown letter \(letter) in level data")
        }
    }
    
    func getTilePosition(row: Int, column: Int) -> CGPoint {
        let xPos = (64 * column) + 32
        let yPos = (64 * row) + 32
        return CGPoint(x: xPos, y: yPos)
    }
    
    func addWall(at location: CGPoint) {
        let wall = SKSpriteNode(imageNamed: "block")
        wall.position = location
        wall.zPosition = 0
        wall.physicsBody = SKPhysicsBody(rectangleOf: wall.size)
        wall.physicsBody?.isDynamic = false
        wall.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
        wall.physicsBody?.collisionBitMask = CollisionTypes.player.rawValue
        addChild(wall)
    }
    
    func addVortex(at location: CGPoint) {
        let vortex = SKSpriteNode(imageNamed: "vortex")
        vortex.position = location
        vortex.zPosition = 0
        vortex.physicsBody = SKPhysicsBody(circleOfRadius: vortex.size.width / 2)
        vortex.physicsBody?.isDynamic = false
        vortex.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
        vortex.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        vortex.physicsBody?.collisionBitMask = 0 // Bounces off nothing
        
        let rotateForever = getVortexRotation()
        vortex.run(rotateForever)
        
        vortex.name = "vortex"
        addChild(vortex)
    }
    
    func addStar(at location: CGPoint) {
        let star = SKSpriteNode(imageNamed: "star")
        star.position = location
        star.zPosition = 0
        star.physicsBody = SKPhysicsBody(rectangleOf: star.size)
        star.physicsBody?.isDynamic = false
        star.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
        star.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        star.physicsBody?.collisionBitMask = 0
        
        star.name = "star"
        addChild(star)
    }
    
    func addFinishTile(at location: CGPoint) {
        let finish = SKSpriteNode(imageNamed: "finish")
        finish.position = location
        finish.zPosition = 0
        finish.physicsBody = SKPhysicsBody(rectangleOf: finish.frame.size)
        finish.physicsBody?.isDynamic = false
        finish.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
        finish.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        finish.physicsBody?.collisionBitMask = 0
        finish.name = "finish"
        addChild(finish)
    }
    
    func addPlayer(at location: CGPoint) {
        player = SKSpriteNode(imageNamed: "player")
        player.position = location
        player.zPosition = 1
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue | CollisionTypes.teleport.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        
        addChild(player)
    }
    
    /* Simulator Hacks */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        setLastTouchPosition(for: touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        setLastTouchPosition(for: touches)
    }
    
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        lastTouchPosition = nil
    }
    
    func setLastTouchPosition(for touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
        
    func setGravityToLastTouch() {
        if let lastTouchPosition = lastTouchPosition {
            let xDiff = lastTouchPosition.x - player.position.x
            let yDiff = lastTouchPosition.y - player.position.y
            physicsWorld.gravity = CGVector(dx: xDiff / 100, dy: yDiff / 100)
        }
    }
    
    func setGravityToAccelerometerData() {
        if let accelerometerData = motionManager?.accelerometerData {
            let acceleration = accelerometerData.acceleration
            // Switching X and Y as the device is flipped
            // Y axis is also inverted, thus multiply by -ve
            let xDiff = acceleration.y * ACCELEROMETER_FACTOR * -1
            let yDiff = acceleration.x * ACCELEROMETER_FACTOR
            physicsWorld.gravity = CGVector(dx: xDiff, dy: yDiff)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        if nodeA == player {
            playerCollided(with: nodeB)
        } else if nodeB == player {
            playerCollided(with: nodeA)
        }
    }
    
    func playerCollided(with node: SKNode) {
        if node.name == "star" {
            playerDidCollideWithStar(node)
        } else if node.name == "vortex" {
            playerDidCollideWithVortex(node)
        } else if node.name == "finish" {
            playerDidCollideWithFinish(node)
        } else if node.name == "teleportEntry" {
            playerDidCollideWithTeleportEntry()
        }
//        else if node.name == "teleportExit" {
//            playerDidCollideWithTeleportExit()
//        }
    }
    
    func playerDidCollideWithVortex(_ vortex: SKNode) {
        if vortex.hasActions() {
            vortex.removeAllActions()
            vortex.run(getVortexRotation())
        }
        print("Player collided with Vortex")
        score -= 1
        print("did reach here")
        playerMovable = false
        
        let moveIn = SKAction.move(to: vortex.position, duration: ANIMATION_DURATION)
        let scaleDown = SKAction.scale(to: 0.001, duration: ANIMATION_DURATION)
        let remove = SKAction.removeFromParent()
        let restart = SKAction.run { [weak self] in
            // todo Make this dynamic
            self?.addPlayer(at: CGPoint(x: 96, y: 672))
//            self?.player.speed = 0
            self?.player.physicsBody?.velocity = .zero
            self?.physicsWorld.gravity = .zero
            self?.playerMovable = true
            self?.lastTouchPosition = nil
            print("Respawned player")
        }
        
        print("did reach here")
        
        let actionSequence = SKAction.sequence([moveIn, scaleDown, remove, restart])
        
        player.run(actionSequence)
    }
    
    func playerDidCollideWithStar(_ star: SKNode) {
        score += 1
        
        let pickup = SKAction.sequence(getPickUpActions())
        star.run(pickup)
    }
    
    func playerDidCollideWithFinish(_ finish: SKNode) {
        score += 10
        
        player.physicsBody?.isDynamic = false
        
        var pickup = getPickUpActions()
        let gameOver = SKAction.run { [weak self] in
            self?.player.removeFromParent()
            self?.gameOver()
        }
        pickup.append(gameOver)
        let sequence = SKAction.sequence(pickup)
        finish.run(sequence)
    }
    
    func playerDidCollideWithTeleportEntry() {
        teleportPlayer(from: teleportEntry, to: teleportExit)
    }
    
    func playerDidCollideWithTeleportExit() {
        teleportPlayer(from: teleportExit, to: teleportEntry)
    }
    
    func teleportPlayer(from entry: SKSpriteNode, to exit: SKSpriteNode) {
        playerMovable = false
        var actions = [SKAction]()
        actions += getSuckInAction(at: entry.position) // Suck In
        actions += getSuckOutAction(at: exit.position) // Suck Out
        let makePlayerMovable = SKAction.run { [weak self] in
            self?.playerMovable = true
        }
        actions.append(makePlayerMovable)
        let actionSequence = SKAction.sequence(actions)
        player.run(actionSequence)
    }
    
    func getPickUpActions() -> [SKAction] {
        let scaleUp = SKAction.scale(to: 1.5, duration: ANIMATION_DURATION)
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: ANIMATION_DURATION)
        let hitFX = SKAction.group([scaleUp, fadeOut])
        let removeFromParent = SKAction.removeFromParent()
        return [hitFX, removeFromParent]
    }
    
    func gameOver() {
        addGameOverLabels()
        scoreLabel.removeFromParent()
    }
    
    func addGameOverLabels() {
        let centerX = 512
        let centerY = 384
        let displacedY = 200
        let centerLoc = CGPoint(x: centerX, y: centerY)
        let displacedLoc = CGPoint(x: centerX, y: displacedY)
        
        addGameOverLabel(with: "GAME OVER", at: centerLoc, fontSized: 44)
        addGameOverLabel(with: "Final score: \(score)", at: displacedLoc)
    }
    
    func addGameOverLabel(with text: String, at location: CGPoint, fontSized fontSize: CGFloat = 36) {
        let goLabel = SKLabelNode(fontNamed: "Chalkduster")
        goLabel.fontSize = fontSize
        goLabel.horizontalAlignmentMode = .center
        goLabel.position = location
        goLabel.zPosition = 2
        goLabel.text = text
        addChild(goLabel)
    }
    
    func getVortexRotation() -> SKAction {
        let rotation = SKAction.rotate(byAngle: .pi, duration: 1)
        return SKAction.repeatForever(rotation)
    }
    
    func getSuckInAction(at location: CGPoint) -> [SKAction] {
        let moveIn = SKAction.move(to: location, duration: ANIMATION_DURATION)
        let scaleDown = SKAction.scale(to: 0.001, duration: ANIMATION_DURATION)
        return [moveIn, scaleDown]
    }
    
    func getSuckOutAction(at location: CGPoint) -> [SKAction] {
        let moveTo = SKAction.move(to: location, duration: ANIMATION_DURATION)
        let scaleUp = SKAction.scale(to: 1, duration: ANIMATION_DURATION)
        lastTouchPosition = nil
        return [moveTo, scaleUp]
    }
    
    func addTeleportEntry(at location: CGPoint) {
        addTeleport(at: location, isEntry: true)
    }
    
    func addTeleportExit(at location: CGPoint) {
        addTeleport(at: location, isEntry: false)
    }
    
    func addTeleport(at location: CGPoint, isEntry: Bool) {
        let teleport = SKSpriteNode(imageNamed: "vortex")
        teleport.colorBlendFactor = 0.8

        teleport.position = location
        teleport.run(getVortexRotation())
        teleport.physicsBody = SKPhysicsBody(circleOfRadius: teleport.size.width / 2)
        teleport.physicsBody?.isDynamic = false
        teleport.physicsBody?.categoryBitMask = CollisionTypes.teleport.rawValue
        teleport.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        teleport.physicsBody?.collisionBitMask = 0
        addChild(teleport)
        if isEntry {
            teleportEntry = teleport
            teleportEntry.color = .green
            teleportEntry.name = "teleportEntry"
        } else {
            teleportExit = teleport
            teleportExit.color = .blue
            teleportExit.name = "teleportExit"
        }
    }
    
}
