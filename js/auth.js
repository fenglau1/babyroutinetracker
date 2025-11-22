/**
 * Auth.js
 * Handles Authentication and User State
 */

const Auth = {
    user: null,

    init() {
        auth.onAuthStateChanged(user => {
            this.user = user;
            this.updateUI();
            if (user) {
                console.log("User logged in:", user.email);
                Store.syncData(); // Trigger sync on login
            } else {
                console.log("User logged out");
            }
        });
    },

    login() {
        const provider = new firebase.auth.GoogleAuthProvider();
        auth.signInWithPopup(provider)
            .then((result) => {
                // User signed in
            }).catch((error) => {
                console.error("Login failed", error);
                alert("Login failed: " + error.message);
            });
    },

    logout() {
        auth.signOut().then(() => {
            // Sign-out successful.
            // Optional: Clear local data or keep it? 
            // For now, we keep local data but stop syncing.
            alert("Signed out");
        }).catch((error) => {
            console.error("Logout failed", error);
        });
    },

    updateUI() {
        const loginBtn = document.getElementById('login-btn');
        const logoutBtn = document.getElementById('logout-btn');
        const userInfo = document.getElementById('user-info');
        const userName = document.getElementById('user-name');
        const userAvatar = document.getElementById('user-avatar');

        if (this.user) {
            loginBtn.classList.add('hidden');
            logoutBtn.classList.remove('hidden');
            userInfo.classList.remove('hidden');
            userName.textContent = this.user.displayName;
            userAvatar.src = this.user.photoURL;
        } else {
            loginBtn.classList.remove('hidden');
            logoutBtn.classList.add('hidden');
            userInfo.classList.add('hidden');
        }
    }
};
