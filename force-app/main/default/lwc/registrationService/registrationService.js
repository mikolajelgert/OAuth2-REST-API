import { LightningElement } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import sfCloud from '@salesforce/resourceUrl/sfCloud';
import createUserData from '@salesforce/apex/UserController.createUserData';
import setUserPassword from '@salesforce/apex/UserController.setUserPassword';

export default class RegistrationService extends NavigationMixin(LightningElement) {
    isPasswordSet = false;
    images = {
        cloud: sfCloud
    };

    navigateToLogin() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'OAuthLogin__c'
            }
        }, true)
    }

    //createApex user, send template
    handleSubmit(event) {
        const inputs = this.template.querySelectorAll('lightning-input');
        const formatData = {};

        inputs.forEach(input => {
            formatData[input.name] = input.value;
        });
        
        createUserData({userData: formatData}).then((isCreated) => {
            if (isCreated) {
                setTimeout(() => {
                    setUserPassword({email: formatData?.email, password: formatData?.password}).then((result) => {
                        if (result) {
                            console.log('password set successfully')
                            this.isPasswordSet = true;
                        }
                    }).catch(error => {
                        console.log(error);
                    })
                }, 3000);
            }
        })
        .catch(error => {
            console.log(error);
        })
    }
}