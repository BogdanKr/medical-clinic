/**
 * Created by Bogdan_Krasun on 21.12.2022.
 */

import {LightningElement} from 'lwc';
import {NavigationMixin} from "lightning/navigation";

export default class ClinicMain extends LightningElement {
    isLoading = false;

    // Handles loading event
    handleLoading() {
        this.isLoading = true;
    }

    // Handles done loading event
    handleDoneLoading() {
        this.isLoading = false;
    }

    // Handles choose specialization event
    // This custom event comes from the specialization list component
    searchDoctors(event) {
        let specializationId = event.detail.specializationId;
        this.template.querySelector('c-doctor-search-results').searchDoctors(specializationId);
    }

    createNewSpecialization() {
        // Navigate to the Specialization home page
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Specialization__c',
                actionName: 'new',
            },
        });
    }

}