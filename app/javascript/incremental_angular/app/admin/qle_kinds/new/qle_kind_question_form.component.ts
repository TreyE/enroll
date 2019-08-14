import { Component, Injector, ElementRef, Inject, ViewChild, Input } from '@angular/core';
import { FormGroup, FormControl, AbstractControl, FormArray, FormBuilder, Validators } from '@angular/forms';
import { QuestionComponentRemover } from './question_component_remover';
import { QleKindResponseFormComponent } from './qle_kind_question_response_form.component';


@Component({
  selector: 'qle-question-form',
  templateUrl: './qle_kind_question_form.component.html'
})

export class QleKindQuestionFormComponent {
  @Input("questionFormGroup")
  public questionFormGroup : FormGroup | null;
  
  @Input("questionIndex")
  public questionIndex : number | null;
  
  @Input("questionComponentParent")
  public questionComponentParent : QuestionComponentRemover | null;
  
  constructor(private _questionForm: FormBuilder) {
  }

  ngOnInit() {
  }

  public getResponseArray() : FormGroup[] {
    if (this.questionFormGroup != null) {
      var responses = <FormArray>this.questionFormGroup.get('responses');
      if (responses != null) {
        return responses.controls.map(function(r_control) {
          return <FormGroup>r_control;
        });
      }
    }
    return [];
  }

  public removeQuestion() {
    if (this.questionComponentParent != null) {
      if (this.questionIndex != null) {
        this.questionComponentParent.removeQuestion(this.questionIndex);
      }
    }
  }

  public showResponseForm() : boolean {
    var responses = <FormGroup[]>this.getResponseArray();
    if (responses != null) {
      return responses.length > 0;
    }
    return false;
  }


  removeResponse(responseIndex: number) {
    if(this.questionFormGroup != null) {
      var responses : FormArray | null = <FormArray>this.questionFormGroup.get('responses');
      if (responses != null) {
        responses.removeAt(responseIndex);
      }
    }
  }

  public addResponse(){
    if (this.questionFormGroup != null) {
      var control : FormArray | null = <FormArray>this.questionFormGroup.get('responses');
      if (control){
        var responseFormGroup = QleKindResponseFormComponent.newResponseFormGroup();
        control.push(responseFormGroup); 
      }
    }
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }

  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  // public responseArray : FormArray;
 public static newQuestionFormGroup(formBuilder: FormBuilder) : FormGroup {
    var questionForm = new FormGroup({
      content: new FormControl('', Validators.required),
      responses: new FormArray([])
    });
    return questionForm
  }

}
