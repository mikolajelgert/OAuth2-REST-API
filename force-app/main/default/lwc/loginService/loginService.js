import { LightningElement } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import sfCloud from '@salesforce/resourceUrl/sfCloud';

export default class LoginContainer extends NavigationMixin(LightningElement) {
    images = {
        cloud: sfCloud
    };

    navigateToRegister() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'OAuthRegister__c'
            }
        }, true);
    }
}