/**
 * Created by Bogdan_Krasun on 21.12.2022.
 */

import {LightningElement, wire} from 'lwc';
import getSpecializations from '@salesforce/apex/DoctorDataService.getSpecializations';

export default class SpecializationList extends LightningElement {
    selectedSpecializationId = '';
    error = undefined;
    specializations;

    // Wire a custom Apex method
    @wire(getSpecializations)
    boatTypes({error, data}) {
        if (data) {
            this.specializations = data
        } else if (error) {
            this.specializations = undefined;
            this.error = error;
        }
    }

    // Fires event that specialization has been chosen.
    handleChosenSpecialization(event) {
        this.selectedSpecializationId = event.detail.recordId;
        const searchEvent = new CustomEvent('search', {
            detail: { specializationId: this.selectedSpecializationId}
        });
        this.dispatchEvent(searchEvent);
    }

}