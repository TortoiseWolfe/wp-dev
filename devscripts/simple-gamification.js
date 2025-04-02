/**
 * Simple BuddyPress Tutorial Gamification
 * 
 * A lightweight client-side gamification system for tutorial tracking
 */

document.addEventListener('DOMContentLoaded', function() {
    // Initialize
    initGamification();
});

/**
 * Initialize gamification system
 */
function initGamification() {
    // Get completed tutorials from cookie
    const completedTutorials = getCompletedTutorials();
    
    // Make sure the cookie is properly formatted (fix any potential issues)
    setCookie('bp_tutorial_completed', JSON.stringify(completedTutorials), 30);
    
    // Update UI based on completed tutorials
    updateTutorialUI(completedTutorials);
    
    // Set up event listeners
    setupEventListeners();
}

/**
 * Get completed tutorials from cookie
 */
function getCompletedTutorials() {
    const cookieValue = getCookie('bp_tutorial_completed');
    return cookieValue ? JSON.parse(cookieValue) : [];
}

/**
 * Set up event listeners for buttons
 */
function setupEventListeners() {
    // Mark complete buttons
    const completeButtons = document.querySelectorAll('.mark-complete-button');
    completeButtons.forEach(button => {
        button.addEventListener('click', function() {
            const tutorialSlug = this.getAttribute('data-tutorial-slug');
            markTutorialComplete(tutorialSlug);
        });
    });
    
    // Reset progress buttons - may have multiple on the page
    const resetButtons = document.querySelectorAll('.reset-progress-button');
    resetButtons.forEach(button => {
        button.addEventListener('click', function() {
            resetProgress();
        });
    });
}

/**
 * Mark a tutorial as complete
 */
function markTutorialComplete(tutorialSlug) {
    // Always get a fresh copy of the completed tutorials
    const completedTutorials = getCompletedTutorials();
    
    // Don't add duplicates
    if (!completedTutorials.includes(tutorialSlug)) {
        // Add to completed list
        completedTutorials.push(tutorialSlug);
        
        // Save to cookie with longer expiration to ensure it persists
        setCookie('bp_tutorial_completed', JSON.stringify(completedTutorials), 365);
        
        // Force a refresh of the UI with the updated list
        updateTutorialUI(completedTutorials);
        
        // Show success message
        showNotification('Tutorial completed! +100 points earned');
    }
}

/**
 * Reset all progress
 */
function resetProgress() {
    // Clear the cookie with same expiration as when we set it
    setCookie('bp_tutorial_completed', '[]', 365);
    
    // Force update UI with empty array of completed tutorials
    updateTutorialUI([]);
    
    // Extra cleanup to ensure all checkmarks are removed
    document.querySelectorAll('.tutorial-checkmark').forEach(checkmark => {
        checkmark.remove();
    });
    document.querySelectorAll('.tutorial-link').forEach(link => {
        link.classList.remove('completed');
    });
    
    // Show notification
    showNotification('Progress reset! Starting fresh...');
}

/**
 * Update UI based on completed tutorials
 */
function updateTutorialUI(completedTutorials) {
    // Ensure completedTutorials is an array
    if (!Array.isArray(completedTutorials)) {
        completedTutorials = [];
    }

    const completedCount = completedTutorials.length;
    const totalTutorials = 7;
    const progressPercent = Math.round((completedCount / totalTutorials) * 100);
    
    // Calculate points (100 per tutorial + bonuses)
    let totalPoints = completedCount * 100;
    
    // Add bonus for completing "Getting Started" section
    const gettingStartedSlugs = [
        'introduction-to-buddypress',
        'installing-and-configuring-buddypress',
        'customizing-member-profiles'
    ];
    
    const completedGettingStarted = gettingStartedSlugs.every(slug => 
        completedTutorials.includes(slug)
    );
    
    if (completedGettingStarted) {
        totalPoints += 150; // Bonus points
    }
    
    // Add bonus for completing all tutorials
    if (completedCount === totalTutorials) {
        totalPoints += 500; // Master achievement bonus
    }
    
    // Update progress bars
    const progressBars = document.querySelectorAll('.tutorial-progress-bar');
    progressBars.forEach(bar => {
        bar.style.width = progressPercent + '%';
    });
    
    // Update progress text
    const progressTexts = document.querySelectorAll('.tutorial-progress-text');
    progressTexts.forEach(text => {
        text.textContent = completedCount + ' of ' + totalTutorials + ' tutorials completed';
    });
    
    // Update points text
    const pointsTexts = document.querySelectorAll('.tutorial-points-text');
    pointsTexts.forEach(text => {
        text.textContent = totalPoints + ' points earned';
    });
    
    // Update curriculum page links if we're on that page
    const tutorialLinks = document.querySelectorAll('.tutorial-link');
    tutorialLinks.forEach(link => {
        const slug = link.getAttribute('data-tutorial-slug');
        if (completedTutorials.includes(slug)) {
            // Mark as completed
            link.classList.add('completed');
            
            // Add checkmark if not already there
            if (!link.querySelector('.tutorial-checkmark')) {
                const checkmark = document.createElement('span');
                checkmark.className = 'tutorial-checkmark';
                checkmark.textContent = '✓';
                link.insertBefore(checkmark, link.firstChild);
            }
        } else {
            // Remove completed class
            link.classList.remove('completed');
            
            // Remove checkmark if exists
            const checkmark = link.querySelector('.tutorial-checkmark');
            if (checkmark) {
                link.removeChild(checkmark);
            }
        }
    });
    
    // Update current tutorial page if we're on one
    const tutorialBox = document.querySelector('.tutorial-completion-box');
    if (tutorialBox) {
        const tutorialSlug = tutorialBox.getAttribute('data-tutorial-slug');
        const isCompleted = completedTutorials.includes(tutorialSlug);
        
        const completeButton = document.querySelector('.mark-complete-button');
        const completedMessage = document.querySelector('.completed-message');
        const nextButton = document.querySelector('.next-tutorial-button');
        
        if (isCompleted) {
            tutorialBox.classList.add('completed');
            if (completeButton) completeButton.style.display = 'none';
            if (completedMessage) completedMessage.style.display = 'block';
            if (nextButton) nextButton.style.display = 'inline-block';
        } else {
            tutorialBox.classList.remove('completed');
            if (completeButton) completeButton.style.display = 'inline-block';
            if (completedMessage) completedMessage.style.display = 'none';
            if (nextButton) nextButton.style.display = 'none';
        }
    }
    
    // Update achievements
    updateAchievements(completedTutorials);
}

/**
 * Update achievements based on completed tutorials
 */
function updateAchievements(completedTutorials) {
    // Getting Started Master
    const gettingStartedSlugs = [
        'introduction-to-buddypress',
        'installing-and-configuring-buddypress',
        'customizing-member-profiles'
    ];
    
    const completedGettingStarted = gettingStartedSlugs.every(slug => 
        completedTutorials.includes(slug)
    );
    
    const gettingStartedAchievement = document.querySelector('.achievement-getting-started');
    if (gettingStartedAchievement) {
        if (completedGettingStarted) {
            gettingStartedAchievement.classList.remove('locked');
            gettingStartedAchievement.classList.add('unlocked');
        } else {
            gettingStartedAchievement.classList.remove('unlocked');
            gettingStartedAchievement.classList.add('locked');
        }
    }
    
    // Group Manager
    const groupManagerAchievement = document.querySelector('.achievement-group-manager');
    if (groupManagerAchievement) {
        if (completedTutorials.includes('creating-and-managing-groups')) {
            groupManagerAchievement.classList.remove('locked');
            groupManagerAchievement.classList.add('unlocked');
        } else {
            groupManagerAchievement.classList.remove('unlocked');
            groupManagerAchievement.classList.add('locked');
        }
    }
    
    // Theme Explorer
    const themeExplorerAchievement = document.querySelector('.achievement-theme-explorer');
    if (themeExplorerAchievement) {
        if (completedTutorials.includes('introduction-to-buddyx-theme')) {
            themeExplorerAchievement.classList.remove('locked');
            themeExplorerAchievement.classList.add('unlocked');
        } else {
            themeExplorerAchievement.classList.remove('unlocked');
            themeExplorerAchievement.classList.add('locked');
        }
    }
    
    // Discussion Master
    const discussionMasterAchievement = document.querySelector('.achievement-discussion-master');
    if (discussionMasterAchievement) {
        if (completedTutorials.includes('setting-up-group-discussions')) {
            discussionMasterAchievement.classList.remove('locked');
            discussionMasterAchievement.classList.add('unlocked');
        } else {
            discussionMasterAchievement.classList.remove('unlocked');
            discussionMasterAchievement.classList.add('locked');
        }
    }
    
    // Theme Customizer
    const themeCustomizerAchievement = document.querySelector('.achievement-theme-customizer');
    if (themeCustomizerAchievement) {
        if (completedTutorials.includes('customizing-buddyx-appearance')) {
            themeCustomizerAchievement.classList.remove('locked');
            themeCustomizerAchievement.classList.add('unlocked');
        } else {
            themeCustomizerAchievement.classList.remove('unlocked');
            themeCustomizerAchievement.classList.add('locked');
        }
    }
    
    // BuddyPress Master
    const bpMasterAchievement = document.querySelector('.achievement-bp-master');
    if (bpMasterAchievement) {
        if (completedTutorials.length === 7) {
            bpMasterAchievement.classList.remove('locked');
            bpMasterAchievement.classList.add('unlocked');
        } else {
            bpMasterAchievement.classList.remove('unlocked');
            bpMasterAchievement.classList.add('locked');
        }
    }
}

/**
 * Show notification
 */
function showNotification(message) {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = 'tutorial-notification';
    notification.textContent = message;
    document.body.appendChild(notification);
    
    // Show notification
    setTimeout(() => {
        notification.classList.add('show');
        
        // Hide after delay
        setTimeout(() => {
            notification.classList.remove('show');
            
            // Remove from DOM after fade out
            setTimeout(() => {
                document.body.removeChild(notification);
            }, 500);
        }, 3000);
    }, 10);
}

/**
 * Helper: Get cookie value
 */
function getCookie(name) {
    const match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
    return match ? match[2] : null;
}

/**
 * Helper: Set cookie
 */
function setCookie(name, value, days) {
    let expires = '';
    if (days) {
        const date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        expires = '; expires=' + date.toUTCString();
    }
    document.cookie = name + '=' + value + expires + '; path=/';
}