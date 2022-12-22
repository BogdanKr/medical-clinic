/**
 * Created by Bogdan_Krasun on 21.12.2022.
 */

import {api, LightningElement, wire} from 'lwc';
import {MessageContext, publish} from "lightning/messageService";
import DOCMC from '@salesforce/messageChannel/DoctorMessageChannel__c';
import getDoctors from '@salesforce/apex/DoctorDataService.getDoctors';


export default class DoctorSearchResults extends LightningElement {
    selectedDoctorId;
    specializationId = '';
    doctors;

    @wire(MessageContext)
    messageContext;

    @wire(getDoctors, {specializationId: '$specializationId'})
    wireDoctors(result) {
        if (result) {
            this.doctors = result;
        }
        this.notifyLoading(false);
    }

    // receive specializationId to load doctors
    @api searchDoctors(specializationId) {
        this.notifyLoading(this.isLoading);
        this.specializationId = specializationId;
    }


    updateSelectedTile(event) {
        this.selectedDoctorId = event.detail.selectedDoctorId;
        this.sendMessageService(this.selectedDoctorId);
    }

    // Publishes the selected Doctor Id on the DOC message channel.
    sendMessageService(selectedDoctorId) {
        // explicitly pass boatId to the parameter recordId
        const payload = {recordId: selectedDoctorId};
        publish(this.messageContext, DOCMC, payload);
    }

    // bobbled event to load spinner
    notifyLoading(isLoading) {
        if (isLoading) {
            const loadEvent = new CustomEvent('loading');
            this.dispatchEvent(loadEvent);
        } else {
            const loadEvent = new CustomEvent('doneloading');
            this.dispatchEvent(loadEvent);
        }
    }

}