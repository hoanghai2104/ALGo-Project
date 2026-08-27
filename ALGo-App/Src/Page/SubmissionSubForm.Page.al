page 50103 SubmissionSubForm
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = SoumissionLine;
    MultipleNewLines = true;
    AutoSplitKey = true;
    RefreshOnActivate = true;
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
                    trigger OnValidate()
                    begin
                        // if (Rec.Type = Rec.Type::Article) and (Rec.Quantity = 0) then begin
                        //     Rec.Validate(Quantity, 1);
                        //     Rec.CalcFields("Unit Price");
                        //     this.SoummissonCodeunit.validateSoumissionLine(Rec);

                        // end; //unused

                        CurrPage.Update(true);
                    end;

                }
                field(Designation; Rec.Designation)
                {
                    Editable = true;
                    StyleExpr = this.CustomStyle;

                }
                field("Description Supp."; Rec."Description Supp.")
                {
                    Editable = true;
                    StyleExpr = this.CustomStyle;
                }
                field("Code RPLP"; Rec."Code RPLP")
                {
                    Enabled = true;
                    StyleExpr = this.CustomStyle;

                }
                field(Totalisation; Rec.Totalisation)
                {
                    StyleExpr = this.CustomStyle;
                    Editable = this.IsTotalisationEnable;
                    trigger OnValidate()
                    begin
                        if Rec.Type = Rec.Type::Formule then begin
                            Rec."Montant net" := Rec.CalculateTotalFromRange(Rec.Totalisation, Rec."Soumission ID");
                            CurrPage.Update(true);
                        end;
                    end;
                }
                field(Quantity; Rec.Quantity)
                {
                    StyleExpr = this.PrixAlert;
                    Editable = not this.IsEditable;
                    ShowMandatory = not this.IsEditable;
                    BlankZero = true;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    Editable = false;
                    Enabled = false;
                }

                field("Unit Price"; Rec."Unit Price (base)")
                {
                    StyleExpr = this.CustomStyle;
                    BlankZero = true;
                    Editable = not this.IsEditable;

                }
                field(Remise; Rec.Remise)
                {
                    StyleExpr = this.PrixAlert;
                    Editable = not this.IsEditable;
                    BlankZero = true;
                }
                field("% OB"; Rec."% OB")
                {
                    StyleExpr = this.PrixAlert;
                    Editable = not this.IsEditable;
                    BlankZero = true;

                }
                field("Prix Unitaire net"; Rec."Prix Unitaire net")
                {
                    StyleExpr = this.PrixAlert;
                    Editable = not this.IsEditable;
                    BlankZero = true;
                }
                field("Montant net"; Rec."Montant net")
                {
                    StyleExpr = this.PrixAlert;
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
                    DecimalPlaces = 2;
                }
                field("Total VAT"; TotalVat)
                {
                    Editable = false;
                    DecimalPlaces = 2;

                }
                field("Total Incl. VAT"; TotalSoumissionLine."Amount Including Vat")
                {
                    Editable = false;
                    DecimalPlaces = 2;

                }
            }
        }

    }

    actions
    {
        area(Processing)
        {
            action(InsertExtTexts)
            {
                ApplicationArea = All;
                Caption = 'Insert &Ext. Texts';
                Image = Text;
                ToolTip = 'Insert the extended item description that is set up for the item that is being processed on the line.';

                trigger OnAction()
                var
                    soumissionLineSelected: Record SoumissionLine;
                begin
                    soumissionLineSelected.Reset();
                    CurrPage.SetSelectionFilter(soumissionLineSelected);
                    if soumissionLineSelected.FindFirst() then
                        insertExtText(soumissionLineSelected);
                end;
            }
            action(RecalculateLineNumbers)
            {
                Visible = false;
                Enabled = false;

                ApplicationArea = All;
                Caption = 'Recalcule des N° de lignes';
                Image = Refresh;
                ToolTip = 'Renumber all lines in increments of 10,000 to free up space for new line insertions.';

                trigger OnAction()
                begin
                    Rec.RenumberLines();
                    CurrPage.Update(false);
                end;
            }

        }
    }


    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        this.SoummissonCodeunit.validateSoumissionLine(Rec);
        this.setEditable();
        this.totalVatCalculation();
        this.UpdateTotalisation();
        // CurrPage.Update(false);
    end;

    trigger OnModifyRecord(): Boolean

    begin
        this.SoummissonCodeunit.validateSoumissionLine(Rec);
        this.setEditable();
        this.setStyle();
        this.SellingPriceAlert(true);
        this.totalVatCalculation();
        this.UpdateTotalisation();
        CurrPage.Update(false);

    end;

    trigger OnAfterGetRecord()

    begin
        this.setStyle();
        this.SellingPriceAlert(false);
        this.setEditable();
        this.totalVatCalculation();
        this.UpdateTotalisation();

        CurrPage.Update(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec.Type.AsInteger() = 0 then begin
            Rec.Validate(Type, Rec.Type::Article);
            this.IsEditable := false;
        end;
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

    procedure UpdateTotalisation()
    var
        soumissionLine: Record SoumissionLine;
    begin
        if (Rec.Type = Rec.Type::Article) then begin
            soumissionLine.Reset();
            soumissionLine.SetLoadFields("Soumission ID", "Montant net", "Montant Totalisation", Totalisation, Type);
            soumissionLine.SetRange("Soumission ID", Rec."Soumission ID");
            soumissionLine.SetRange(Type, soumissionLine.Type::Formule);
            if soumissionLine.FindSet() then
                repeat
                    soumissionLine."Montant net" := soumissionLine.CalculateTotalFromRange(soumissionLine.Totalisation, Rec."Soumission ID");
                    soumissionLine."Montant Totalisation" := soumissionLine."Montant net";
                    soumissionLine.Modify();
                until soumissionLine.Next() = 0;
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

    procedure insertExtText(var soumissionLine: Record SoumissionLine)
    begin
        if soumissionLine.Count = 1 then begin
            if soumissionLine.Type <> Rec.type::Article then
                exit;
            // if Rec.FindFirst() then begin
            soumissionLine.InsertItemExtText(soumissionLine.No);
            // end;
        end;

    end;

    local procedure SellingPriceAlert(Message: Boolean): Boolean
    begin
        // if (xRec.Remise = Rec.Remise) or (xRec."% OB" = Rec."% OB") then
        //     exit;

        if this.SoummissonCodeunit.SellingPriceAlert(Rec, Message) then
            this.PrixAlert := Format(Enum::StyleProperty::Attention)
        else
            this.PrixAlert := this.CustomStyle;

    end;

    var
        TotalSoumissionLine: Record SoumissionLine;
        SoummissonCodeunit: Codeunit Soumission;
        CustomStyle, PrixAlert : Text[100];
        IsEditable, IsTotalisationEnable : Boolean;
        TotalVat: Decimal;

}