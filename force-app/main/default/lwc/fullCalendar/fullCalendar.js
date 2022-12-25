/**
 * Created by Bogdan_Krasun on 23.12.2022.
 */

import {LightningElement, track, wire} from 'lwc';
import {loadScript, loadStyle} from 'lightning/platformResourceLoader';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import FullCalendarJS from '@salesforce/resourceUrl/FullCalendarJS2';
import {refreshApex} from '@salesforce/apex';
import {APPLICATION_SCOPE, MessageContext, subscribe} from "lightning/messageService";
import DOCMC from '@salesforce/messageChannel/DoctorMessageChannel__c';

import getDoctorEvents from '@salesforce/apex/GoogleCalendarService.getPrimaryCalendarEventsByDoctor'
import upsertEvent from '@salesforce/apex/GoogleCalendarService.upsertEvent';
import deleteEvent from '@salesforce/apex/GoogleCalendarService.deleteEventById';

export default class FullCalendar extends LightningElement {
    //To avoid the recursion from renderedcallback
    fullCalendarJsInitialised = false;

    //Fields to store the event data -- add all other fields you want to add
    title='';
    description='';
    startDate = new Date();
    endDate = new Date();

    eventsRendered = false;//To render initial events only once
    // openSpinner = false; //To open the spinner in waiting screens
    openModal = false; //To open form

    doctorId;
    eventId = '';
    myEvent;

    @track
    events = []; //all calendar events are stored in this field

    //To store the orignal wire object to use in refreshApex method
    eventOriginalData = [];

    //Get data from server - in this example, it fetches from the event object
    @wire(getDoctorEvents, {doctorId: '$doctorId'})
    eventObj(value) {
        const {data, error} = value;
        if (data) {
            this.eventOriginalData = value; //To use in refresh cache
            //format as fullcalendar event object
            console.log(data);
            let events = data.map(event => {
                return {
                    id: event.id,
                    title: event.summary,
                    description: event.description,
                    start: event.start.dateTime_c,
                    end: event.end_c.dateTime_c,
                    allDay: false
                };
            });
            this.events = [];
            this.events = JSON.parse(JSON.stringify(events));
            console.log(this.events);
            this.error = undefined;
            //load only on first wire call -

            // if events are not rendered, try to remove this 'if' condition and add directly
            if (!this.eventsRendered) {
                //Add events to calendar
                const ele = this.template.querySelector("div.fullcalendarjs");
                $(ele).fullCalendar('renderEvents', this.events, true);
                this.eventsRendered = true;
            }
        } else if (error) {
            this.error = 'No events are found';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            this.showNotification('Oops', this.error, 'error');
            this.events = [];
        }
        // console.log('refresh apex');
        return refreshApex(this.eventOriginalData);
    }

    /**
     * Load the fullcalendar.io in this lifecycle hook method
     */
    renderedCallback() {
        // Performs this operation only on first render
        if (this.fullCalendarJsInitialised) {
            return;
        }
        this.fullCalendarJsInitialised = true;

        // Executes all loadScript and loadStyle promises
        // and only resolves them once all promises are done
        Promise.all([
            loadStyle(this, FullCalendarJS + "/FullCalendarJS/fullcalendar.min.css"),
            loadScript(this, FullCalendarJS + "/FullCalendarJS/jquery.min.js"),
            loadScript(this, FullCalendarJS + "/FullCalendarJS/moment.min.js"),
            loadScript(this, FullCalendarJS + "/FullCalendarJS/fullcalendar.min.js"),
        ])
            .then(() => {
                //initialize the full calendar
                this.initialiseFullCalendarJs();
            })
            .catch((error) => {
                console.error({
                    message: "Error occured on FullCalendarJS",
                    error,
                });
            });
    }

    initialiseFullCalendarJs() {
        const ele = this.template.querySelector("div.fullcalendarjs");
        // const modal = this.template.querySelector('div.modalclass');
        console.log(FullCalendar);

        let self = this;

        //To open the form with predefined fields
        function openActivityForm(eventId, title, description, startDate, endDate) {
            self.eventId = eventId;
            self.title = title;
            self.description = description;
            self.startDate = startDate;
            self.endDate = endDate;
            self.openModal = true;
        }

        function setMyEvent(event) {
            self.myEvent = event;
        }

        function updateEvent(event) {
            console.log('starting drag update event!2 ');

            let newEvent = {
                id: event.id, title: event.title, description: event.description,
                start: event.start, end: event.end, doctorId: self.doctorId
            };
            console.log('process drag update = ' + newEvent.title);
            upsertEvent({'obj': JSON.stringify(newEvent)})
                .then(() => {
                    self.showNotification('Success!!', 'Your event has been updated', 'success');
                    //refresh the grid
                    return refreshApex(self.eventOriginalData);
                })
                .catch(error => {
                    console.log(error);
                    self.showNotification('Oops', 'Something went wrong, please review console', 'error');
                })
        }

        //Actual fullcalendar renders here - https://fullcalendar.io/docs/v3/view-specific-options
        $(ele).fullCalendar({
            header: {
                left: "prev,next today",
                center: "title",
                right: "month,agendaWeek,agendaDay",
            },
            defaultDate: new Date(), // default day is today - to show the current date
            defaultView: 'agendaWeek', //To display the default view - as of now it is set to week view
            navLinks: true, // can click day/week names to navigate views
            editable: true, // To move the events on calendar
            eventDrop: function (event, delta, revertFunc) {
                // alert(event.title + " was changed " + event.start.format());
                if (!confirm("Are you sure about this change?")) {
                    revertFunc();
                } else {
                    updateEvent(event);
                }
            },
            eventResize: function (event, delta, revertFunc) {
                if (!confirm("Are you sure about this change?")) {
                    revertFunc();
                } else {
                    updateEvent(event);
                }
            },
            selectable: true, //To select the period of time
            //To select the time period : https://fullcalendar.io/docs/v3/select-method
            select: function (startDate, endDate) {
                let stDate = startDate.format();
                let edDate = endDate.format();
                openActivityForm('', '', '', stDate, edDate);
            },
            eventLimit: true, // allow "more" link when too many events
            events: this.events, // all the events that are to be rendered - can be a duplicate statement here
            eventClick: function (calEvent, jsEvent, view) {
                openActivityForm(calEvent.id, calEvent.title, calEvent.description, calEvent.start.format(), calEvent.end.format());
                setMyEvent(calEvent);
                // change the border color
                $(this).css('border-color', 'red');
            },
        });
    }

    //TODO: add the logic to support multiple input texts
    handleKeyup(event) {
        this.title = event.target.value;
    }

    //To close the modal form
    handleCancel() {
        this.openModal = false;
    }

    //To save the event
    handleSave() {
        // this.openSpinner = true;
        console.log('handle save fires');
        //get all the field values - as of now they all are mandatory to create a standard event
        this.template.querySelectorAll('lightning-input').forEach(ele => {
            if (ele.name === 'title') {
                this.title = ele.value;
            }
            if (ele.name === 'start') {
                this.startDate = ele.value.includes('.000Z') ? ele.value : ele.value + '.000Z';
                this.myEvent.startDate = ele.value;
            }
            if (ele.name === 'end') {
                this.endDate = ele.value.includes('.000Z') ? ele.value : ele.value + '.000Z';
                this.myEvent.endDate = ele.value;
            }
        });
        this.template.querySelectorAll('lightning-textarea').forEach(ele => {
            if (ele.name === 'description') {
                this.description = ele.value;
            }
        });

        console.log('MyEvent = ' + this.myEvent);
        this.myEvent.title = this.title;
        this.myEvent.description = this.description;

        //format as per fullcalendar event object to create and render
        let newEvent = {
            id: this.eventId, title: this.title, description: this.description,
            start: this.startDate, end: this.endDate, doctorId: this.doctorId
        };

        //Close the modal
        this.openModal = false;
        this.makeUpsertToDB(newEvent);
    }

    makeUpsertToDB(newEvent) {
        let isUpdated = this.eventId !== '';
        const ele = this.template.querySelector("div.fullcalendarjs");
        console.log('process makeUpsertToDB = ' + newEvent.title);
        console.log('ele0 = ' + ele);
        //Server call to create or update the event
        upsertEvent({'obj': JSON.stringify(newEvent)})
            .then(result => {
                //To populate the event on fullcalendar object
                //Id should be unique and useful to remove the event from UI - calendar
                newEvent.id = result;
                console.log('ele = ' + ele);

                if (isUpdated) {
                    console.log('updated this.myEvent Id 3- ' + this.myEvent.id + ' this.myEvent title - ' + this.myEvent.title);
                    console.log('updated this.myEvent startTime !! ' + this.myEvent.start.format() + ' this.myEvent endTime - ' + this.myEvent.end.format());
                    $(ele).fullCalendar('updateEvent', newEvent);
                    $(ele).fullCalendar('updateEvent', this.myEvent);
                    this.openModal = false;
                    this.showNotification('Success!!', 'Your event has been updated', 'success');
                    //refresh the grid
                    return refreshApex(this.eventOriginalData);
                } else {
                    //renderEvent is a fullcalendar method to add the event to calendar on UI
                    //Documentation: https://fullcalendar.io/docs/v3/renderEvent
                    console.log('new eventId 3- ' + newEvent.id + ' title - ' + newEvent.title);
                    console.log('new startTime ' + newEvent.start + ' endTime - ' + newEvent.end);
                    $(ele).fullCalendar('renderEvent', newEvent, true);
                    //To display on UI with id from server
                    this.events.push(newEvent);
                }
                //To close spinner and modal
                // this.openSpinner = false;
                //show toast message
                this.showNotification('Success!!', 'Your event has been logged', 'success');
            })
            .catch(error => {
                console.log(error);
                // this.openSpinner = false;
                //show toast message - TODO
                this.showNotification('Oops', 'Something went wrong, please review console', 'error');
            })
    }

    /**
     * @description: remove the event with id
     * @documentation: https://fullcalendar.io/docs/v3/removeEvents
     */
    removeEvent(event) {
        //open the spinner
        // this.openSpinner = true;
        // console.log('spinner is - ' + this.openSpinner);
        //delete the event from server and then remove from UI
        let eventId = event.target.value;
        let removeObj = {id: eventId, doctorId: this.doctorId};
        console.log('removeObj id - ' + removeObj.id + ' doctorId - ' + removeObj.doctorId);
        deleteEvent({'removeObj': JSON.stringify(removeObj)})
            .then(result => {
                console.log('delete result - ' - result);
                const ele = this.template.querySelector("div.fullcalendarjs");
                console.log('ele = ' + ele);
                console.log('delete EventId - ' + eventId);
                $(ele).fullCalendar('removeEvents', [eventId]);

                // this.openSpinner = false;
                this.openModal = false;

                //refresh the grid
                this.showNotification('Success!!', 'Your event has deleted', 'success');
                return refreshApex(this.eventOriginalData);
            })
            .catch(error => {
                console.log('catch error log - ' + error);
                // this.openSpinner = false;
                this.openModal = false;
                this.showNotification('Oops', 'Something went wrong, please review console', 'error');
            });
    }

    clearCalendar() {
        const ele = this.template.querySelector("div.fullcalendarjs");
        $(ele).fullCalendar('removeEvents');
    }

    /**
     *  @description open the modal by nullifying the inputs
     */
    addEvent() {
        this.startDate = null;
        this.endDate = null;
        this.title = null;
        this.openModal = true;
    }

    /**
     * @description method to show toast events
     */
    showNotification(title, message, variant) {
        console.log('enter');
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
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
            (message) => this.handleMessage(message),
            {scope: APPLICATION_SCOPE}
        );
    }

    // Handler for message received by component
    handleMessage(message) {
        if (this.doctorId !== message.recordId) {
            console.log('Clear events and update doctor');
            this.clearCalendar();
            this.eventsRendered = false;
            this.doctorId = message.recordId;
        }
    }

    connectedCallback() {
        this.subscribeMC();
    }
}