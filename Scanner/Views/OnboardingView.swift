//
//  OnboardingView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    private let pages = OnboardingPage.pages
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    AppColors.backgroundDarkStart,
                    AppColors.backgroundDarkEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: {
                        completeOnboarding()
                    }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // Carousel
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? AppColors.pageIndicatorActive : AppColors.pageIndicatorInactive)
                            .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppColors.buttonSecondaryBackground)
                            )
                        }
                    }
                    
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            if currentPage < pages.count - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: pages[currentPage].color.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon with animated background
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                page.color.opacity(0.3),
                                page.color.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .blur(radius: 20)
                
                // Icon container
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    page.color.opacity(0.2),
                                    page.color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            page.color.opacity(0.5),
                                            page.color.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    
                    Image(systemName: page.icon)
                        .font(.system(size: 70, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [page.color, page.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
            }
            .padding(.top, 60)
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
        }
    }
}

#Preview {
    OnboardingView()
}
