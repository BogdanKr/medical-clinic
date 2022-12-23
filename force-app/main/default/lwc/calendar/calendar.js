/**
 * Created by Bogdan_Krasun on 22.12.2022.
 */

import {LightningElement, api, track} from 'lwc';
import FullCalendarJS from '@salesforce/resourceUrl/fullcalendarv3';
// import FullCalendarJS from '@salesforce/resourceUrl/FullCalendarJS';

import {loadStyle, loadScript} from 'lightning/platformResourceLoader';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class Calendar extends LightningElement {
    jsInitialised = false;
    @track
    _events;

    @api
    get events() {
        return this._events;
    }

    set events(value) {
        console.log('setting events in calendar - ' + value);
        // this.eventDataString = '';
        this._events = [...value];
        value.forEach(v=> {
            console.log('event.Id = ' + v.Id);
            console.log('event.summary = ' + v.title);
            console.log('event.start = ' + v.start);
            console.log('event.end_c = ' + v.end);
        });
    }


    @api
    get eventDataString() {
        return this.events;
    }

    set eventDataString(value) {
        try {
            this.events = eval(value);
        } catch {
            this.events = [];
        }
    }

    renderedCallback() {
        // Performs this operation only on first render
        if (this.jsInitialised) {
            return;
        }
        this.jsInitialised = true;

        Promise.all([
            loadStyle(this, FullCalendarJS + '/FullCalenderV3/fullcalendar.min.css'),
            loadScript(this, FullCalendarJS + '/FullCalenderV3/jquery.min.js'),
            loadScript(this, FullCalendarJS + '/FullCalenderV3/moment.min.js'),
            loadScript(this, FullCalendarJS + '/FullCalenderV3/fullcalendar.min.js'),
            // loadScript(this, FullCalendarJS + "/FullCalendarJS/jquery.min.js"),
            // loadScript(this, FullCalendarJS + "/FullCalendarJS/moment.min.js"),
            // loadScript(this, FullCalendarJS + "/FullCalendarJS/fullcalendar.min.js"),
            // loadStyle(this, FullCalendarJS + "/FullCalendarJS/fullcalendar.min.css"),
        ])
            .then(() => {
                this.initialiseCalendarJs();
                console.log('Initialize calendar!');
                // this.events = '[{"title":"MY TEST!","start":"2022-12-23","end":"2022-12-18"}]';
            })
            .catch(error => {
                alert(error);
                new ShowToastEvent({
                    title: 'Error!',
                    message: error,
                    variant: 'error'
                })
            })
    }

    renderEvents(){
        console.log('Render events');
        $(ele).fullCalendar('renderEvents', this.events, true);
    }

    initialiseCalendarJs() {
        let that = this;
        const ele = this.template.querySelector('div.fullcalendarjs');
        //Use jQuery to instantiate fullcalender JS
        $(ele).fullCalendar({
            header: {
                left: 'prev,next today',
                center: 'title',
                right: 'month,basicWeek,basicDay'
            },
            defaultDate: new Date(),
            navLinks: true,
            editable: true,
            eventLimit: true,
            events: this.events,
            dragScroll: true,
            droppable: true,
            weekNumbers: true,
            selectable: true,
            // eventClick: this.eventClick,
            eventClick: function (info) {
                const selectedEvent = new CustomEvent('eventclicked', {detail: info.Id});
                // Dispatches the event.
                that.dispatchEvent(selectedEvent);
            }
        });
    }
}