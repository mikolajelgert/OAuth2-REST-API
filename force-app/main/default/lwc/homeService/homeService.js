import { LightningElement, wire } from 'lwc';
import sfBear from '@salesforce/resourceUrl/sfBear';
import sfCloud from '@salesforce/resourceUrl/sfCloud';
import { NavigationMixin } from "lightning/navigation";
import getLastUsers from '@salesforce/apex/UserController.getLastUsers';

const COLUMNS = [
    {label: 'Created Date', fieldName: 'CreatedDate'},
    {label: 'Id', fieldName: 'Id'},
    {label: 'Username', fieldName: 'Username'},
    {label: 'Email', fieldName: 'Email'},
    {label: 'Profile', fieldName: 'ProfileName'}
];

export default class HomeService extends NavigationMixin(LightningElement) {
    hasGuestAccess = false;
    images = {
        bear: sfBear,
        cloud: sfCloud
    };
    columns = COLUMNS;
    data;
    timer = '01:00';

    get logoutTimer() {
        return this.timer;
    }

    connectedCallback() {;
        setTimeout(() => this.startLogoutTimer(), 500);
        this.collectUsers();
    }

    startLogoutTimer() {
        let time = 60;

        const countdown = setInterval(() => {
            time--;
            const minutes = String(Math.floor(time / 60)).padStart(2, '0');
            const seconds = String(time % 60).padStart(2, '0');
            this.timer = `${minutes}:${seconds}`;

            if (time < 0) {
                clearInterval(countdown);
                this.navigateToLogin();
            }
        }, 1000);
    }

    navigateToLogin() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'OAuthLogin__c'
            }
        }, true)
    }

    collectUsers() {
        getLastUsers().then(users => {
            this.data = users.map(user => ({
                ...user,
                ProfileName: user.Profile?.Name
            }));
        })
        .catch(error => {
            console.error(error);
        })
    }
}