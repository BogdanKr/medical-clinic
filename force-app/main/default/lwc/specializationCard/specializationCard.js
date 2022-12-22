/**
 * Created by Bogdan_Krasun on 21.12.2022.
 */

import {api, LightningElement} from 'lwc';
const TILE_WRAPPER_SELECTED_CLASS = 'tile-wrapper selected';
const TILE_WRAPPER_UNSELECTED_CLASS = 'tile-wrapper';

export default class SpecializationCard extends LightningElement {
    @api specialization;
    changeStyle = false;

    // Getter for dynamically setting the background image for the picture
    get backgroundStyle() {
        return 'background-image:url(' + this.specialization.Image_Url__c + ')';
    }

    // Getter for dynamically setting border of the card
    get tileClass() {
        return this.changeStyle ? TILE_WRAPPER_SELECTED_CLASS : TILE_WRAPPER_UNSELECTED_CLASS;
    }

    setClass(){
        this.changeStyle = !this.changeStyle;
    }

    // Fires event that specialization has been chosen.
    handleChosenSpecialization() {
        console.log('onclick card event - ' + this.specialization.Id);
        console.log('background-image:url - ' + this.specialization.Image_Url__c);
        const searchEvent = new CustomEvent('specializationselect', {
            detail: { specializationId: this.specialization.Id}
        });
        this.dispatchEvent(searchEvent);
    }

}