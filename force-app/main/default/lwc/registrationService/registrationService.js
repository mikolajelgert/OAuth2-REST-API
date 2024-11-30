import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import sfCloud from '@salesforce/resourceUrl/sfCloud';
import createUserData from '@salesforce/apex/UserController.createUserData';
import setUserPassword from '@salesforce/apex/UserController.setUserPassword';
import checkUsername from '@salesforce/apex/UserController.checkUsername';

export default class RegistrationService extends NavigationMixin(LightningElement) {
    isPasswordSet = false;
    images = {
        cloud: sfCloud
    };
    isUserCreated = true;
    allInputsValid = false;
    isUserExist = false;
    isVisible = false;
    @api message = '';

    get areInputsFilled() {
        return !this.allInputsValid;
    }

    get bodyInputs() {
        return this.isUserCreated ? 'body-inputs' : 'body-inputs-blur';
    }

    get backToLogin() {
        return this.isPasswordSet ? 'back-to-login-passwordSet' : 'back-to-login';
    }

    get usernameInputClass() {
        return this.isUserExist ? 'input-error' : '';
    }

    @api showToast(message) {
        this.message = message;
        this.isVisible = true;
        setTimeout(() => {
            this.isVisible = false;
        }, 5000);
    }

    navigateToLogin() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'OAuthLogin__c'
            }
        }, true)
    }

    handleInputChange() {
        const inputs = this.template.querySelectorAll('lightning-input');
        const allValid = Array.from(inputs).every(input => {
            const isValid = input.checkValidity(); 
            return isValid && input.value.length > 0;
        });
        this.allInputsValid = allValid;
    }

    handleSubmit() {
        const inputs = this.template.querySelectorAll('lightning-input');
        const formatData = {};

        inputs.forEach(input => {
            formatData[input.name] = input.value;
        });

        if (this.allInputsValid) {
            checkUsername({username: formatData?.username}).then(response => {
                const responseObj = JSON.parse(response);
                if (response.length > 0 && (responseObj.totalSize > 0 || responseObj.records.length > 0)) {
                    this.isUserExist = true;
                    this.allInputsValid = false;
                } else {
                    this.isUserCreated = false;
                    this.allInputsValid = false;
                    createUserData({userData: formatData}).then((isCreated) => {
                        if (isCreated) {
                            setTimeout(() => {
                                setUserPassword({email: formatData?.email, password: formatData?.password}).then((result) => {
                                    if (result) {
                                        this.showToast('Username: ' + formatData?.username);
                                        this.isPasswordSet = true;
                                        this.isUserCreated = true;
                                    }
                                }).catch(error => {
                                    console.log(error);
                                })
                            }, 3000);
                        }
                    })
                    .catch(error => {
                        console.log(error);
                    });
                }
            });
        }
    }

    resetFlag() {
        this.isUserExist = false;
    }
}