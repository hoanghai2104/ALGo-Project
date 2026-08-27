page 50105 SoumissionSummary
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = SoumissionLine;
    MultipleNewLines = true;
    AutoSplitKey = true;
    ModifyAllowed = false;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = 'Impression Soumission';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Soumission ID"; Rec."Soumission ID")
                {
                    StyleExpr = this.CustomStyle;
                    Enabled = false;
                    Visible = false;

                }
                field("Line No"; Rec."Line No")
                {
                    StyleExpr = this.CustomStyle;
                    Enabled = false;
                    BlankZero = true;
                    // Visible = false;

                }
                field(Type; Rec.Type)
                {
                    StyleExpr = this.CustomStyle;
                    Visible = false;

                }
                field(No; Rec.No)
                {
                    Lookup = true;
                    LookupPageId = "Item List";
                    StyleExpr = this.CustomStyle;
                    Editable = not this.IsEditable;
                    Visible = false;
                }
                field(Designation; Rec.Designation)
                {
                    Editable = this.IsEditable;
                    StyleExpr = this.CustomStyle;

                }
                field(Totalisation; Rec.Totalisation)
                {
                    StyleExpr = this.CustomStyle;
                    Editable = this.IsTotalisationEnable;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    StyleExpr = this.CustomStyle;
                    Editable = not this.IsEditable;
                    Visible = false;

                }
                field("Unit Price"; Rec."Unit Price (base)")
                {
                    StyleExpr = this.CustomStyle;
                    Visible = false;

                }
                field(Remise; Rec.Remise)
                {
                    StyleExpr = this.CustomStyle;
                    Editable = not this.IsEditable;
                    Visible = false;

                }
                field("% OB"; Rec."% OB")
                {
                    StyleExpr = this.CustomStyle;
                    Editable = not this.IsEditable;
                    Visible = false;

                }
                field("Prix Unitaire net"; Rec."Prix Unitaire net")
                {
                    StyleExpr = this.CustomStyle;
                    Editable = not this.IsEditable;
                    BlankZero = true;

                }
                field("Montant net"; Rec."Montant net")
                {
                    StyleExpr = this.CustomStyle;
                    Editable = not this.IsEditable;
                    BlankZero = true;
                    Visible = false;

                }
                field("Montant Totalisation"; Rec."Montant Totalisation")
                {
                    caption = 'Montant net';
                    StyleExpr = this.CustomStyle;
                    Editable = not this.IsEditable;
                    BlankZero = true;
                }
                field("Style Property"; Rec."Style Property")
                {
                    StyleExpr = this.CustomStyle;
                    Visible = false;

                }

            }
        }

    }

    actions
    {
        area(Processing)
        {


        }
    }

    trigger OnAfterGetRecord()
    begin
        this.setStyle();
        this.setEditable();

    end;

    procedure setStyle()
    begin
        this.CustomStyle := Format(Rec."Style Property");
    end;

    procedure setEditable()
    begin
        this.IsTotalisationEnable := Rec.type = Rec.Type::Formule ? true : false;

        if Rec.Type <> Rec.Type::Article then begin
            this.IsEditable := true;
        end else begin
            this.IsEditable := false;
        end;
    end;


    var
        CustomStyle: Text[100];
        IsEditable, IsTotalisationEnable : Boolean;


}