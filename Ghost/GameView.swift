//
//  ContentView.swift
//  Ghost
//
//  Created by Pavel Zak on 27/10/2020.
//

import SwiftUI

class Game : ObservableObject {
    enum State {
        case intro
        case running
        case finished
    }
    
    var board = Board(size: 5)
    var ghost = Ghost()
    
    @Published var state: State = .intro
    @Published var score: Int = 0
    
    private var currentInterval: Double = 0.4
    
    func isGhostCollision()-> Bool {
        guard let firstTile = self.board.firstTile else {
            return false
        }
        return firstTile.hasObject
    }
    
    
    func is👻InDanger() -> Bool {
        self.board.tiles.filter{
            $0.x<3 && $0.y<3 &&
            $0.x>0 && $0.y>0 && $0.hasObject
        }.count>0
    }
    
    
    func generateObstacles() {
        let treshold = 0.8-min(Double(score)*0.01, 1.0)*0.2
        let tiles = self.board.lastTiles(self.board.directionRight)
        tiles.forEach { $0.hasObject = Double.random(in: 0..<1)>treshold }
    }
    
    func clearObstacles() {
        self.board.tiles.filter {$0.x == -1 || $0.y == -1}.forEach{$0.hasObject = false}
    }
    
    func animateGhostFace() {
        guard !self.ghost.doingFace && Double.random(in: 0..<1)>0.7 else {
            return
        }
        
        if self.is👻InDanger() {
            self.ghost.roarAndClose()
        }
        else {
            self.ghost.smileAndClose()
        }
    }
    
    func gameStep() {
        self.clearObstacles()
        
        self.animateGhostFace()
        
        withAnimation(Animation.easeOut(duration: self.currentInterval)) {
            self.board.move()
            self.generateObstacles()
        }
        
        if self.isGhostCollision() {
            DispatchQueue.main.asyncAfter(deadline: .now() + currentInterval) {
                withAnimation() {
                    self.state = .finished
                }
            }
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + currentInterval*1.5) {
                self.gameStep()
            }
            self.currentInterval = max(self.currentInterval - 0.002, 0.15)
            self.score += 1
        }
    }
    
    func start() {
        withAnimation() {
            self.state = .running
        }
        self.score = 0
        self.board.clear()
        self.gameStep()
    }
}


struct GameView: View {
    @ObservedObject var game = Game()
    var body: some View {
        VStack {
            Text("")
                .padding(.top, 20)
            HStack {
                Spacer()
                Button(action: {
                    self.game.board.directionRight = false
                }) {
                    Image(systemName: "chevron.left.2")
                        .font(.largeTitle)
                        .foregroundColor(Color("TileLight"))
                        .frame(width: 80, height: 160)
                }
                Spacer()
                BoardView (board: self.game.board, ghost: self.game.ghost)
                Spacer()
                Button(action: {
                    self.game.board.directionRight = true
                }) {
                    Image(systemName: "chevron.right.2")
                        .font(.largeTitle)
                        .foregroundColor(Color("TileLight"))
                        .frame(width: 80, height: 160)
                }
                Spacer()
            }
            Text("\(self.game.score)")
                .font(.headline)
                .foregroundColor(Color("TileLight"))
                .padding(.bottom, 20)
        }
        .frame(maxWidth:.infinity, maxHeight: .infinity)
        .background(LinearGradient(gradient: Gradient(colors: [Color("BackgroundLight"), Color("Background")]), startPoint: UnitPoint(x: 0.4, y: 0), endPoint: UnitPoint(x: 0.5, y: 1)))
        .ignoresSafeArea()
        .onAppear{
            self.game.start()
        }
        .blur(radius: self.game.state != .finished ? 0 : 10.0)
        .overlay(self.game.state == .finished ? EndView(game: self.game) : nil)
    }
}
