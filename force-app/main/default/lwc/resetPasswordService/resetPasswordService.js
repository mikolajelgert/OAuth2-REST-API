import { LightningElement } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import sfCloud from '@salesforce/resourceUrl/sfCloud';
import checkUsername from '@salesforce/apex/UserController.checkUsername';
import checkPassword from '@salesforce/apex/UserController.checkPassword';

export default class LoginContainer extends NavigationMixin(LightningElement) {
    images = {
        cloud: sfCloud
    };
    username;
    password;
    isUserNotExists = false;
    isPasswordValid = true;


    get usernameInputClass() {
        return this.isUserNotExists ? 'input-error' : '';
    }

    get areCredentialsCorrect() {
        return this.isUserNotExists || !this.isPasswordValid || (!this.username || !this.password);
    }

    navigateToRegister() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'OAuthRegister__c'
            }
        }, true);
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
                //set password
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