import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import sfCloud from '@salesforce/resourceUrl/sfCloud';
import checkUsername from '@salesforce/apex/UserController.checkUsername';
import checkPassword from '@salesforce/apex/UserController.checkPassword';
//import { publish } from 'c/pubsub';
// import { publish, MessageContext } from 'lightning/messageService';
// import USER_ACCESS_CHANNEL from '@salesforce/messageChannel/User_Access__c';

export default class LoginContainer extends NavigationMixin(LightningElement) {
    // @wire(MessageContext)
    // messageContext;

    images = {
        cloud: sfCloud
    };
    username;
    password;
    isUserNotExists = false;
    isPasswordIncorrect = false;

    get usernameInputClass() {
        return this.isUserNotExists ? 'input-error' : '';
    }

    get passwordInputClass() {
        return this.isPasswordIncorrect ? 'input-error' : '';
    }

    get areCredentialsCorrect() {
        return this.isUserNotExists || this.isPasswordIncorrect || (!this.username || !this.password);
    }

    navigateToRegister() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'OAuthRegister__c'
            }
        }, true);
    }

    navigateToResetPassword() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'OAuthResetPassword__c'
            }
        }, true);
    }

    navigateToHome() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Home'
            }
        }, true);
    }

    handleUsername(event) {
        this.username = (event.target.value).trim();
    }

    handlePassword(event) {
        this.password = (event.target.value).trim();
    }

    checkCredentials(event) {
        checkUsername({username: this.username}).then(response => {
            const responseObj = JSON.parse(response);
            if (response.length > 0 && (responseObj.totalSize == 0 || responseObj.records.length == 0)) {
                this.isUserNotExists = true;
            } else {
                checkPassword({username: this.username, password: this.password}).then(response => {
                    const responseObj = JSON.parse(response);
                    if (responseObj.hasOwnProperty("error")) {
                        this.isPasswordIncorrect = true;
                    } else {
                        //const payload = {userAccess: 'jajco'};
                        //publish('userAccessEvent', payload);
                        sessionStorage.setItem('userAccess', true);
                        this.navigateToHome();
                        //publishUserAccess(payload);
                        //publish(this.messageContext, USER_ACCESS_CHANNEL, payload);
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

    // async publishUserAccess(payload) {
    //     await publish(this.messageContext, USER_ACCESS_CHANNEL, payload);
    //     // try {
    //     //     await this.navigateToHome();
    //     // } catch (error) {
    //     //     console.error(error);
    //     // }
    // }

    resetFlag() {
        this.isUserNotExists = false;
        this.isPasswordIncorrect = false;
    }
}