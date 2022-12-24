/**
 * Created by Bogdan_Krasun on 23.12.2022.
 */

import {LightningElement, track, wire} from 'lwc';
import {loadScript, loadStyle} from 'lightning/platformResourceLoader';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import FullCalendarJS from '@salesforce/resourceUrl/FullCalendarJS2';
// import fetchEvents from '@salesforce/apex/FullCalendarController.fetchEvents';

import getDoctorEvents from '@salesforce/apex/GoogleCalendarService.getPrimaryCalendarEventsByDoctor'
import upsertEvent from '@salesforce/apex/GoogleCalendarService.upsertEvent';
import deleteEvent from '@salesforce/apex/GoogleCalendarService.deleteEventById';
import {refreshApex} from '@salesforce/apex';

export default class FullCalendar extends LightningElement {
    //To avoid the recursion from renderedcallback
    fullCalendarJsInitialised = false;

    //Fields to store the event data -- add all other fields you want to add
    title;
    description;
    startDate;
    endDate;

    eventsRendered = false;//To render initial events only once
    openSpinner = false; //To open the spinner in waiting screens
    openModal = false; //To open form

    doctorId = '003Dn000007Ao8hIAC';
    eventId='';
    @track
    events = []; //all calendar events are stored in this field

    //To store the orignal wire object to use in refreshApex method
    eventOriginalData = [];

    //Get data from server - in this example, it fetches from the event object
    @wire(getDoctorEvents, {doctorId: '$doctorId'})
    eventObj(value) {
        this.eventOriginalData = value; //To use in refresh cache

        const {data, error} = value;
        if (data) {
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
            this.events = [];
            this.error = 'No events are found';
        }
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
        const modal = this.template.querySelector('div.modalclass');
        console.log(FullCalendar);

        let self = this;

        //To open the form with predefined fields
        //TODO: to be moved outside this function
        function openActivityForm(eventId, title, description, startDate, endDate) {
            self.eventId = eventId;
            self.title = title;
            self.description = description;
            self.startDate = startDate;
            self.endDate = endDate;
            self.openModal = true;
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
            // editable: true, // To move the events on calendar - TODO
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
    handleCancel(event) {
        this.openModal = false;
    }

    //To save the event
    handleSave(event) {
        let events = this.events;
        this.openSpinner = true;

        //get all the field values - as of now they all are mandatory to create a standard event
        //TODO- you need to add your logic here.
        this.template.querySelectorAll('lightning-input').forEach(ele => {
            if (ele.name === 'title') {
                this.title = ele.value;
            }
            if (ele.name === 'start') {
                this.startDate = ele.value.includes('.000Z') ? ele.value : ele.value + '.000Z';
            }
            if (ele.name === 'end') {
                this.endDate = ele.value.includes('.000Z') ? ele.value : ele.value + '.000Z';
            }
        });
        this.template.querySelectorAll('lightning-textarea').forEach(ele => {
            if (ele.name === 'description') {
                this.description = ele.value;
            }
        });

        //format as per fullcalendar event object to create and render
        let newEvent = {
            id: this.eventId, title: this.title, description: this.description,
            start: this.startDate, end: this.endDate, doctorId: this.doctorId
        };
        let isUpdated = this.eventId !== '';
        //Close the modal
        this.openModal = false;
        const ele = this.template.querySelector("div.fullcalendarjs");

        //Server call to create the event
        upsertEvent({'obj': JSON.stringify(newEvent)})
            .then(result => {

                //To populate the event on fullcalendar object
                //Id should be unique and useful to remove the event from UI - calendar
                newEvent.id = result;
                console.log('ele = ' + ele);

                if (isUpdated) {
                    console.log('updated eventId 3- ' + newEvent.id + ' title - ' + newEvent.title);
                    console.log('updated startTime ' + newEvent.start + ' endTime - ' + newEvent.end);
                    $(ele).fullCalendar('updateEvent', newEvent);
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
                this.openSpinner = false;

                //show toast message
                this.showNotification('Success!!', 'Your event has been logged', 'success');

            })
            .catch(error => {
                console.log(error);
                this.openSpinner = false;

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
        this.openSpinner = true;
        console.log('spinner is - ' + this.openSpinner);
        //delete the event from server and then remove from UI
        let eventId = event.target.value;
        let removeObj = {id: this.eventId, doctorId: this.doctorId};
        console.log('removeObj id - ' + removeObj.id + ' doctorId - ' + removeObj.doctorId);
        deleteEvent({'removeObj': JSON.stringify(removeObj)})
            .then(result => {
                console.log('delete result - ' - result);
                const ele = this.template.querySelector("div.fullcalendarjs");
                console.log('ele = ' + ele);
                console.log('delete EventId - ' + eventId);
                $(ele).fullCalendar('removeEvents', [eventId]);

                this.openSpinner = false;
                this.openModal = false;

                //refresh the grid
                this.showNotification('Success!!', 'Your event has deleted', 'success');
                return refreshApex(this.eventOriginalData);
            })
            .catch(error => {
                console.log('catch error log - ' + error);
                this.openSpinner = false;
                this.openModal = false;

            });
    }

    /**
     *  @description open the modal by nullifying the inputs
     */
    addEvent(event) {
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
}