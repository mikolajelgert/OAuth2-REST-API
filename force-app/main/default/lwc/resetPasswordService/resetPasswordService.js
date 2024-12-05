import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import sfCloud from '@salesforce/resourceUrl/sfCloud';
import checkUsername from '@salesforce/apex/UserController.checkUsername';
import setUserPassword from '@salesforce/apex/UserController.setUserPassword';

export default class LoginContainer extends NavigationMixin(LightningElement) {
    images = {
        cloud: sfCloud
    };
    username;
    password;
    isUserNotExists = false;
    isPasswordValid = true;
    isVisible = false;
    @api message = '';

    @api showToast(message) {
        this.message = message;
        this.isVisible = true;
        setTimeout(() => {
            this.isVisible = false;
        }, 5000);
    }

    get usernameInputClass() {
        return this.isUserNotExists ? 'input-error' : '';
    }

    get areCredentialsCorrect() {
        return this.isUserNotExists || !this.isPasswordValid || (!this.username || !this.password);
    }

    navigateToLogin() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'OAuthLogin__c'
            }
        }, true)
    }

    handleUsername(event) {
        this.username = event.target.value;
    }

    handlePassword(event) {
        const target = event.target;
        this.password = target.value;
        this.isPasswordValid = target.checkValidity();
    }

    checkCredentials(event) {
        checkUsername({username: this.username}).then(response => {
            const responseObj = JSON.parse(response);
            if (response.length > 0 && (responseObj.totalSize == 0 || responseObj.records.length == 0)) {
                this.isUserNotExists = true;
            } else {
                setUserPassword({username: this.username, password: this.password}).then((result) => {
                    if (result) {
                        this.showToast('Password reseted successfully!');
                        setTimeout(() => {
                            this.navigateToLogin();
                        }, 2000);
                    }
                }).catch(error => {
                    console.log(error);
                })
            }
        })
        .catch(error => {
            console.log(error);
        })
    }

    resetFlag() {
        this.isUserNotExists = false;
    }
}