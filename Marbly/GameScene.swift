//
//  GameScene.swift
//  Marbly
//
//  Created by Atin Agnihotri on 27/08/21.
//

import SpriteKit
import GameplayKit

enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
}

class GameScene: SKScene {
    
    override func didMove(to view: SKView) {
        loadLevel(1)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func loadLevel(_ level: Int) {
        addBackground()
        
        let levelData = loadLevelFile(level)

        addElements(for: levelData)
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
        wall.physicsBody = SKPhysicsBody(rectangleOf: wall.size)
        wall.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
        wall.physicsBody?.isDynamic = false
        wall.physicsBody?.categoryBitMask = 0
        addChild(wall)
    }
    
    func addVortex(at location: CGPoint) {
        let vortex = SKSpriteNode(imageNamed: "vortex")
        vortex.position = location
        vortex.physicsBody = SKPhysicsBody(circleOfRadius: vortex.size.width / 2)
        vortex.physicsBody?.isDynamic = false
        vortex.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
        vortex.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        vortex.physicsBody?.collisionBitMask = 0 // Bounces off nothing
        
        let rotation = SKAction.rotate(byAngle: .pi, duration: 1)
        let rotateForever = SKAction.repeatForever(rotation)
        vortex.run(rotateForever)
        
        vortex.name = "vortex"
        addChild(vortex)
    }
    
    func addStar(at location: CGPoint) {
        let star = SKSpriteNode(imageNamed: "star")
        star.position = location
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
        finish.physicsBody = SKPhysicsBody(rectangleOf: finish.frame.size)
        finish.physicsBody?.isDynamic = false
        finish.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
        finish.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        finish.physicsBody?.collisionBitMask = 0
        finish.name = "finish"
        addChild(finish)
    }
}
