/**
 * Created by Bogdan_Krasun on 21.12.2022.
 */

import {api, LightningElement} from 'lwc';
const TILE_WRAPPER_SELECTED_CLASS = 'tile-wrapper selected';
const TILE_WRAPPER_UNSELECTED_CLASS = 'tile-wrapper';

export default class SpecializationCard extends LightningElement {
    @api specialization;
    @api selectedSpecializationId;
    changeStyle = false;

    // Getter for dynamically setting the background image for the picture
    get backgroundStyle() {
        return 'background-image:url(' + this.boat.Picture__c + ')';
    }

    // Getter for dynamically setting the tile class based on whether the
    // current boat is selected
    get tileClass() {
        return this.changeStyle ? TILE_WRAPPER_SELECTED_CLASS : TILE_WRAPPER_UNSELECTED_CLASS;
    }

    // Fires event with the Id of the specialization that has been selected.
    selectSpecialization() {
        this.changeStyle = true;
        const clickedSpecialization = new CustomEvent('onspecializationselect', {
            detail: { specializationId: this.selectedSpecializationId}
        });
        this.dispatchEvent(clickedSpecialization);
    }

}