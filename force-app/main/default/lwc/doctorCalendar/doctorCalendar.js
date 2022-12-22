/**
 * Created by Bogdan_Krasun on 22.12.2022.
 */

import {LightningElement, track, wire} from 'lwc';
import getDoctorEvents from '@salesforce/apex/GoogleCalendarService.getPrimaryCalendarEventsByDoctor'
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {APPLICATION_SCOPE, MessageContext, subscribe} from "lightning/messageService";
import DOCMC from '@salesforce/messageChannel/DoctorMessageChannel__c';

const ERROR_TITLE = 'Error loading  Calendar events';
const ERROR_VARIANT = 'error';

export default class DoctorCalendar extends LightningElement {
    @track
    startDate = new Date();
    @track
    endDate;
    error;
    openModal = false;
    @track
    events = [];
    doctorId;

    @wire(getDoctorEvents, {doctorId: '$doctorId'})
    eventObj(value) {
        const {data, error} = value;
        console.log('received events = ' + data);
        if (data) {
            //format as fullcalendar event object
            let records = data.map(event => {
                console.log('event.Id = ' + event.Id);
                console.log('event.summary = ' + event.summary);
                console.log('event.start = ' + event.start);
                console.log('event.end_c = ' + event.end_c);
                return {
                    Id: event.Id,
                    title: event.summary,
                    start: event.start,
                    end: event.end_c,
                    allDay: event.IsAllDayEvent
                };
            });
            this.events = JSON.parse(JSON.stringify(records));
            this.error = undefined;
        } else if (error) {
            this.events = [];
            this.dispatchEvent(
                new ShowToastEvent({
                    title: ERROR_TITLE,
                    message: error.body.message,
                    variant: ERROR_VARIANT
                })
            );
            // this.error = 'No events are found';
        }
    }

    handleEvent(event) {
        let id = event.detail;
        let task = this.events.find(x => x.Id = id);
        this.startDate = task.start;
        this.title = task.title;
        this.endDate = task.end;
        this.openModal = true;

    }

    handleCancel(event) {
        this.openModal = false;
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