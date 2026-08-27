tableextension 50101 SalesLine extends "Sales Line"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50100; "% OB"; Decimal)
        {
            Caption = '% OB';
            MinValue = 0;

            trigger OnValidate()
            begin
                if "% OB" < 0 then
                    Error('Impossible de mettre une valeur négative pour le champ %% OB.');

                // Si valeur = 0, on remet le montant OB ligne à vide
                if "% OB" = 0 then
                    "Montant OB ligne" := 0;

                OBCalculator.CalcOBLineAmount(Rec);

            end;
        }

        field(50101; "Montant OB ligne"; Decimal)
        {
            Caption = 'Montant OB ligne';
            Editable = false;
        }
        field(50102; "Code RPLP"; Integer)
        {
            TableRelation = RplpParametrage."Code ID";
            BlankZero = true;
        }

        field(50103; "Description Supp."; Text[500])
        {
            Caption = 'Description Supp.';
            //DataClassification = CustomerContent; // Utilise approprié: CustomerContent, ToBeClassified, etc.
        }
        field(50104; "% Remise articles"; Decimal)
        {
            MinValue = 0;
            trigger OnValidate()
            begin
                if Rec."% Remise articles" < 0 then
                    Error('Impossible de mettre une valeur négative pour le champ %% Remise article.');

                // Si valeur = 0, on remet le montant OB ligne à vide
                if Rec."% Remise articles" = 0 then
                    Rec."Remise article amount" := 0;

                OBCalculator.CalcOBLineAmount(Rec);

            end;
        }
        field(50105; "Remise article amount"; Decimal) { }
        field(50106; "To Order PHM"; Boolean)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                RequisitionWorksheetMgt.CheckToOrderForItemType(Rec);
            end;
        }
    }

    trigger OnModify()
    begin
        OBCalculator.CalcOBLineAmount(Rec);
    end;

    trigger OnDelete()
    begin
        ClearReservedPurchaseLineFields();
    end;

    var
        OBCalculator: Codeunit OBCalculator;
        RequisitionWorksheetMgt: Codeunit RequisitionWorksheet;

    local procedure ClearReservedPurchaseLineFields()
    var
        SalesHeader: Record "Sales Header";
    begin
        RequisitionWorksheetMgt.ClearReservedPurchaseLineFields("Document No.", SalesHeader.TableName(), "Line No.");
    end;
}