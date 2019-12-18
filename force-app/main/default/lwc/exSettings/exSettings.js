/* jshint debug: true */

import { LightningElement, track, wire } from "lwc";
import getFieldValueMap from "@salesforce/apex/MappingServices.getFieldValueMap";
import getMappingFields from "@salesforce/apex/MappingServices.getMappingFields";
import getOrderedKeys from "@salesforce/apex/MappingServices.getOrderedKeys";

export default class exSettings extends LightningElement {
  @track fieldData;
  @track err;
  objectOptions = [
    { value: "Client", label: "Client" },
    { value: "Event", label: "Event" }
  ];

  @track selectedObject = "Event";

  getMapping() {
    //console.dir(this.selectedObject);
    return this.fetchMappingFields
      ? this.fetchMappingFields.$selectedObject
      : [];
  }

  getKeys() {
    //console.dir(this.orderedKeys);
    return this.orderedKeys ? this.orderedKeys.$selectedObject : [];
  }

  @wire(getMappingFields) fetchMappingFields;

  @wire(getOrderedKeys) orderedKeys;

  @wire(getFieldValueMap, { sObjectType: "$selectedObject" }) fetchFieldData(
    data,
    err
  ) {
    //console.log(data);
    if (data) {
      this.fieldData = data;
      this.err = undefined;
    } else if (err) {
      this.err = err;
      this.fieldData = undefined;
    }
  }

  handleChange(event) {
    this.selectedObject = event.target.value;
  }
}
