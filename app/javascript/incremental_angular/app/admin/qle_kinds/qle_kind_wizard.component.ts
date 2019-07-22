import { Component, Injector, ElementRef, ViewChild } from '@angular/core';
import { CategorizedDropdownOption } from '../../dropdown_option';
import { QleKindWizardSelectionComponent } from './wizard/qle_kind_wizard_selection.component';

@Component({
  selector: 'admin-qle-management-wizard',
  templateUrl: './qle_kind_wizard.component.html'
})
export class QleKindWizardComponent {
  public editableList : Array<CategorizedDropdownOption> = [];
  public deactivatableList : Array<CategorizedDropdownOption> = [];

  public newLocation : string | null = null;
  private selectedAction : string | null = null;
  @ViewChild('editSelection') editSelection : QleKindWizardSelectionComponent;
  @ViewChild('deactivateSelection') deactivateSelection : QleKindWizardSelectionComponent;
  @ViewChild('createSelection') createSelection : ElementRef;

  constructor(injector: Injector, private _elementRef : ElementRef) {

  }

  ngOnInit() {
    console.log("hit")
    var editableListJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-editable-list");
    if (editableListJson != null) {
      this.editableList = JSON.parse(editableListJson);
    }
    var deactivatableListJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-deactivatable-list");
    if (deactivatableListJson != null) {
      this.deactivatableList = JSON.parse(deactivatableListJson);
    }
    var newLocationAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-new-location");
    if (newLocationAttribute != null) {
      this.newLocation = newLocationAttribute;
    }
  }

  selectAction(action : string) {
    this.selectedAction = action;
  }

  submit() {
    console.log(this.selectedAction)
    if (this.selectedAction == "new") {
      if (this.newLocation != null) {
        window.location.href = this.newLocation;
      }
    } else if (this.selectedAction == "edit") {
      console.log(this.editSelection)

      var editLocation = this.editSelection.getSelection();
      if (editLocation != null) {
        window.location.href = editLocation;
      }
    } else if (this.selectedAction == "deactivate") {
      var deactivateLocation = this.deactivateSelection.getSelection();
      if (deactivateLocation != null) {
        window.location.href = deactivateLocation;
      }
    }
  }

  showEdit() {
    return(this.selectedAction == "edit");
  }

  showDeactivate() {
    return(this.selectedAction == "deactivate");
  }
  showCreate() {
    return(this.selectedAction == "create");
  }
}