/**
 * Created by Bogdan_Krasun on 22.12.2022.
 */

import {api, LightningElement} from 'lwc';
const TILE_WRAPPER_SELECTED_CLASS = 'tile-wrapper selected';
const TILE_WRAPPER_UNSELECTED_CLASS = 'tile-wrapper';

export default class RecordCard extends LightningElement {
    @api record;
    changeStyle = false;

    // Getter for dynamically setting the background image for the picture
    get backgroundStyle() {
        return 'background-image:url(' + this.record.Image_Url__c + ')';
    }

    // Getter for dynamically setting border of the card
    get tileClass() {
        return this.changeStyle ? TILE_WRAPPER_SELECTED_CLASS : TILE_WRAPPER_UNSELECTED_CLASS;
    }

    get tile(){
        return this.record.Image_Url__c ? 'tile' : '';
    }

    setClass(){
        this.changeStyle = !this.changeStyle;
    }

    // Fires event that specialization has been chosen.
    handleChosenRecord() {
        console.log('onclick card event - ' + this.record.Id)
        const searchEvent = new CustomEvent('recordselect', {
            detail: { recordId: this.record.Id}
        });
        this.dispatchEvent(searchEvent);
    }
}