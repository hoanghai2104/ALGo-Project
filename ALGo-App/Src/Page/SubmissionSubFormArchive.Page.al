page 50107 SubmissionSubFormArchive
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = SoumissionLineArchiveNew;
    MultipleNewLines = true;
    AutoSplitKey = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Devis ID"; Rec."Soumission ID")
                {
                    StyleExpr = this.CustomStyle;
                    Enabled = false;
                    Visible = false;
                }
                field(DocumentNo; Rec.DocumentNo)
                {
                    StyleExpr = this.CustomStyle;
                    Enabled = false;
                }
                field("Line No"; Rec."Line No")
                {
                    StyleExpr = this.CustomStyle;
                    Enabled = false;
                    BlankZero = true;
                }
                field(Type; Rec.Type)
                {
                    StyleExpr = this.CustomStyle;
                }
                field(No; Rec.No)
                {
                    Lookup = true;
                    LookupPageId = "Item List";
                    StyleExpr = this.CustomStyle;
                    Editable = not this.IsEditable;

                }
                field(Designation; Rec.Designation)
                {
                    Editable = this.IsEditable;
                    StyleExpr = this.CustomStyle;

                }
                field("Description Supp."; Rec."Description Supp.")
                {
                    Editable = this.IsEditable;
                    StyleExpr = this.CustomStyle;
                }
                field("Code RPLP"; Rec."Code RPLP")
                {
                    Enabled = false;
                    StyleExpr = this.CustomStyle;

                }
                field(Totalisation; Rec.Totalisation)
                {
                    StyleExpr = this.CustomStyle;
                    Editable = this.IsTotalisationEnable;
                }
                field(Quantity; Rec.Quantity)
                {
                    StyleExpr = this.CustomStyle;
                    Editable = not this.IsEditable;
                    BlankZero = true;

                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    Editable = false;
                    Enabled = false;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    StyleExpr = this.CustomStyle;
                    BlankZero = true;


                }
                field(Remise; Rec.Remise)
                {
                    StyleExpr = this.CustomStyle;
                    Editable = not this.IsEditable;
                    BlankZero = true;

                }
                field("% OB"; Rec."% OB")
                {
                    StyleExpr = this.CustomStyle;
                    Editable = not this.IsEditable;
                    BlankZero = true;


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

                }
                field("Amount Including Vat"; Rec."Amount Including Vat")
                {
                    Editable = false;
                    Enabled = false;
                    BlankZero = true;

                }
                field("Style Property"; Rec."Style Property")
                {
                    StyleExpr = this.CustomStyle;

                }
                field(Gras; Rec.Gras) { }
                field(Italique; Rec.Italique) { }
                field("Souligné"; Rec."Souligné") { }

            }
            group(Total)
            {
                ShowCaption = false;
                field("Total Excl. VAT"; TotalSoumissionLine."Montant net")
                {
                    Editable = false;
                }
                field("Total VAT"; TotalVat)
                {
                    Editable = false;
                }
                field("Total Incl. VAT"; TotalSoumissionLine."Amount Including Vat")
                {
                    Editable = false;
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
        this.totalVatCalculation();

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

    procedure totalVatCalculation()
    begin
        TotalSoumissionLine.Reset();
        TotalSoumissionLine.SetRange("Soumission ID", Rec."Soumission ID");
        TotalSoumissionLine.SetRange(Type, TotalSoumissionLine.Type::Article);

        TotalSoumissionLine.CalcSums("Montant net", "Amount Including Vat");


        TotalVat := TotalSoumissionLine."Amount Including Vat" - TotalSoumissionLine."Montant net";

    end;

    var
        TotalSoumissionLine: Record SoumissionLine;
        CustomStyle: Text[100];
        IsEditable, IsTotalisationEnable : Boolean;
        // RangeID1, RangeID2 : integer;
        TotalVat: Decimal;


}