//
//  MenuScn.swift
// 
//
//  Created by utilisateur on 23/06/2019.
//  Copyright © 2019 SwifTeam. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
    
    
    let background = SKSpriteNode(imageNamed: "background.png")
    
    override func didMove(to view: SKView) {
        
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(background)
    
    }
    
    //Fais la transition vers la GameScene
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let gameScene = GameScene(size: CGSize(width: 667, height: 375))
        
        // use a transition to the gameScene
        let reveal = SKTransition.doorsOpenVertical(withDuration: 1)
        
        // transition from current scene to the new scene
        
        view!.presentScene(gameScene, transition: reveal)
        
    }
}
