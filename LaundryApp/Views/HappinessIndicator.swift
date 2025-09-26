//
//  HappinessIndicator.swift
//  LaundryApp
//
//  Created by Walter Magill on 9/24/25.
//

import SwiftUI

/**
 * ANIMATED HAPPINESS INDICATOR
 *
 * Shows pet happiness as animated hearts that:
 * 1. Decrease over time as pets get dirty
 * 2. Go to 0 (dead/empty hearts) when overdue
 * 3. Animate back up during wash cycles
 * 4. Return to full when cycle is complete
 *
 * HEART LEVELS:
 * - 5 hearts (100-81): Excellent (full red hearts)
 * - 4 hearts (80-61): Good (4 red, 1 gray)
 * - 3 hearts (60-41): Okay (3 red, 2 gray)
 * - 2 hearts (40-21): Poor (2 red, 3 gray)
 * - 1 heart (20-1): Critical (1 red, 4 gray)
 * - 0 hearts (0): Dead (all gray/empty)
 */

struct HappinessIndicator: View {
    let pet: LaundryPet
    @State private var animationAmount: CGFloat = 1.0
    @State private var currentHeartCount: Int = 0
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                heartView(for: index)
                    .scaleEffect(shouldAnimate(heartIndex: index) ? animationAmount : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: animationAmount)
            }
        }
        .onAppear {
            updateHeartCount()
            startHeartAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: pet.currentState) { _, _ in
            updateHeartCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .petUpdateRequired)) { _ in
            // Update hearts when centralized timer fires
            updateHeartCount()
        }
    }
    
    /**
     * HEART VIEW FOR INDIVIDUAL HEART
     */
    @ViewBuilder
    private func heartView(for index: Int) -> some View {
        let heartType = heartTypeForIndex(index)
        
        Group {
            switch heartType {
            case .full:
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
            case .empty:
                Image(systemName: "heart")
                    .foregroundColor(.gray.opacity(0.4))
            case .dead:
                Image(systemName: "heart")
                    .foregroundColor(.black.opacity(0.2))
            }
        }
        .font(.system(size: 10))
    }
    
    /**
     * DETERMINE HEART TYPE FOR INDEX
     */
    private func heartTypeForIndex(_ index: Int) -> HeartType {
        let happiness = pet.currentHappiness
        let heartCount = heartCountForHappiness(happiness)
        
        if happiness == 0 {
            return .dead // All hearts are dead when happiness is 0
        } else if index < heartCount {
            return .full // Red filled heart
        } else {
            return .empty // Gray empty heart
        }
    }
    
    /**
     * CALCULATE HEART COUNT FROM HAPPINESS
     */
    private func heartCountForHappiness(_ happiness: Int) -> Int {
        switch happiness {
        case 81...100: return 5  // Excellent
        case 61...80: return 4   // Good
        case 41...60: return 3   // Okay
        case 21...40: return 2   // Poor
        case 1...20: return 1    // Critical
        default: return 0        // Dead
        }
    }
    
    /**
     * SHOULD ANIMATE HEART
     *
     * Animate hearts when they're recovering (washing/drying states)
     */
    private func shouldAnimate(heartIndex: Int) -> Bool {
        let isRecovering = pet.currentState == .washing || pet.currentState == .drying
        let currentHearts = heartCountForHappiness(pet.currentHappiness)
        
        // Animate the hearts that are currently filled and pet is recovering
        return isRecovering && heartIndex < currentHearts
    }
    
    /**
     * UPDATE HEART COUNT WITH ANIMATION
     */
    private func updateHeartCount() {
        let newHeartCount = heartCountForHappiness(pet.currentHappiness)
        
        if newHeartCount != currentHeartCount {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                currentHeartCount = newHeartCount
            }
        }
    }
    
    /**
     * START HEART ANIMATION
     *
     * Creates pulsing animation for recovery states
     * Uses centralized timer system instead of individual timer
     */
    private func startHeartAnimation() {
        animationAmount = 1.2
        
        // Use centralized timer system instead of individual timer
        // Hearts will update when PetTimerManager posts petUpdateRequired notification
    }
}

/**
 * HEART TYPE ENUMERATION
 */
private enum HeartType {
    case full   // Red filled heart (happy)
    case empty  // Gray outline heart (neutral)
    case dead   // Dark gray/black heart (very sad)
}

/**
 * PREVIEW WITH SAMPLE PET
 */
#Preview {
    VStack(spacing: 20) {
        // Preview different happiness levels
        ForEach([100, 80, 60, 40, 20, 0], id: \.self) { happiness in
            HStack {
                Text("Happiness: \(happiness)")
                Spacer()
                // Create a mock pet for preview
                let mockPet = LaundryPet(type: .clothes)
                HappinessIndicator(pet: mockPet)
            }
            .padding(.horizontal)
        }
    }
    .padding()
}
