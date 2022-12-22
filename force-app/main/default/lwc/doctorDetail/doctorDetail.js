/**
 * Created by Bogdan_Krasun on 22.12.2022.
 */

import {LightningElement, wire} from 'lwc';
import {getFieldValue, getRecord} from "lightning/uiRecordApi";
import {APPLICATION_SCOPE, MessageContext, subscribe} from "lightning/messageService";
import DOCMC from '@salesforce/messageChannel/DoctorMessageChannel__c';
import {NavigationMixin} from "lightning/navigation";

// Contact Schema Imports
import DOCTOR_ID_FIELD from '@salesforce/schema/Contact.Id';
import DOCTOR_NAME_FIELD from '@salesforce/schema/Contact.Name';

const DOCTOR_FIELDS = [DOCTOR_ID_FIELD, DOCTOR_NAME_FIELD];

export default class DoctorDetail extends LightningElement {
    doctorId;
    @wire(getRecord, {recordId: '$doctorId', fields: DOCTOR_FIELDS})
    wiredRecord;

    // Decide when to show or hide the icon
    get detailsTabIconName() {
        return this.wiredRecord.data ? 'standard:people' : null;
    }

    // Utilize getFieldValue to extract the doctor name from the record wire
    get doctorName() {
        return getFieldValue(this.wiredRecord.data, DOCTOR_NAME_FIELD);
    }

    @wire(MessageContext)
    messageContext;
    subscription = null;

    // Subscribe to the message channel
    subscribeMC() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(
            this.messageContext,
            DOCMC,
            (message) => (this.doctorId = message.recordId),
            {scope: APPLICATION_SCOPE}
        );
    }

    connectedCallback() {
        this.subscribeMC();
    }
}