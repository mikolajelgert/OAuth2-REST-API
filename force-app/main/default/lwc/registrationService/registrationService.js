import { LightningElement } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import sfCloud from '@salesforce/resourceUrl/sfCloud';

export default class RegistrationService extends NavigationMixin(LightningElement) {
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
        
        console.log(JSON.stringify(formatData));
    }
}