table 50103 "SoumissionLine"
{
    DataClassification = CustomerContent;
    Caption = 'Soumission Line';
    AllowInCustomizations = AsReadOnly;


    fields
    {
        field(1; "Soumission ID"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "No"; Code[20])
        {
            TableRelation = if (Type = const(Article)) Item."No.";
            trigger OnValidate()
            var
                item: Record Item;
            begin
                if Rec.Type <> Rec.Type::Article then
                    this.FieldError(No, 'Invalid');
                if item.Get(Rec.No) then begin
                    Rec.Designation := item.Description;
                    Rec."VAT Prod. Posting Group" := item."VAT Prod. Posting Group";
                    Rec."Code RPLP" := item."Code RPLP";
                    // Rec."Unit Price (base)" := item."Unit Price";
                    this.getSalesPriceListItemDetail();

                    // if item."Automatic Ext. Texts" = true then
                    //     this.InsertItemExtText(rec.No);
                end;
                // Rec.Quantity := 0;
                if (Rec.Type = Rec.Type::Article) and (Rec.Quantity = 0) then begin
                    Rec.Quantity := 1;

                end;

                this.Soumission.validateSoumissionLine(Rec);
                Rec."Prix Unitaire net" := 0;

            end;
        }

        field(3; "Line No"; Integer)
        {
            Caption = 'No Ligne';
        }
        field(4; "Type"; Enum SubmissionType)
        {
            BlankZero = true;
        }
        field(5; "Designation"; Text[100])
        {
            Caption = 'Désignation';

        }
        field(6; "Totalisation"; Text[50])
        {
            ToolTip = 'Format de totalisation: 1000..3000';
            trigger OnValidate()
            begin
                // if Rec.Type = Rec.Type::Formule then begin
                //     Rec."Montant net" := Rec.CalculateTotalFromRange(Rec.Totalisation, Rec."Devis ID");
                //     CurrPage.Update(true);
                // end;
            end;
        }
        field(7; "Quantity"; Decimal)
        {
            Caption = 'Quantité';
            trigger OnValidate()
            begin

            end;
        }
        field(8; "Unit Price"; Decimal)
        {
            Caption = 'Prix Unitaire';
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Unit Price" where("No." = field(No)));
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by field "Unit Price (base)"';

        }
        field(23; "Unit Price (base)"; Decimal)
        {
            Caption = 'Prix Unitaire';
        }
        field(9; "Remise"; Decimal)
        {
            Caption = '%remise';
        }
        field(10; "% OB"; Decimal)
        {

        }
        field(11; "Prix Unitaire net"; Decimal)
        {
            Editable = false;

        }
        field(12; "Montant net"; Decimal)
        {
            DecimalPlaces = 2;
        }
        field(13; "Style Property"; Enum StyleProperty) { }
        field(14; "Code RPLP"; Integer)
        {
            BlankZero = true;
            TableRelation = RplpParametrage."Code ID";
        }
        field(15; "Montant Totalisation"; Decimal)
        {
            DecimalPlaces = 2;
        }
        field(16; Gras; Boolean)
        {

        }
        field(17; Italique; Boolean)
        {

        }
        field(18; Souligné; Boolean)
        {

        }
        field(19; "VAT Prod. Posting Group"; Code[20])
        {
            TableRelation = "VAT Product Posting Group";
        }
        field(20; "Amount Including Vat"; Decimal)
        {
            DecimalPlaces = 2;
        }
        field(21; "SalesQuoteLineID"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(22; DocumentNo; Code[20])
        {
            Caption = 'Document No.';
            FieldClass = FlowField;
            CalcFormula = lookup(SoumissionHeader.DocumentNo where("Soumission ID" = field("Soumission ID")));
        }
        field(24; "Description Supp."; Text[500])
        {
            Caption = 'Description Supp.';
            //DataClassification = CustomerContent; // Utilise approprié: CustomerContent, ToBeClassified, etc.
        }

    }

    keys
    {
        key(Key1; "Soumission ID", "Line No")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }


    trigger OnInsert()
    begin
        // this.Soumission.validateSoumissionLine(Rec);
        this.ProcessItemExtText(Rec.No);
    end;

    trigger OnModify()
    var
    begin
        this.Soumission.validateSoumissionLine(Rec);

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    // procedure CalculateTotalFromRange(CodeInput: Text[50]; SoumissionId: code[20]): Decimal
    // var
    //     SoumissionLine: Record SoumissionLine; // Replace with your actual table
    //     StartID: Integer;
    //     EndID: Integer;
    //     RangeParts: List of [Text];
    //     Total: Decimal;
    // begin
    //     if CodeInput = '' then
    //         exit;
    //     // Split the input string by '..'
    //     RangeParts := CodeInput.Split('..');
    //     if RangeParts.Count <> 2 then
    //         Rec.FieldError(Totalisation, 'Invalid format, must be a range: e.g 1000..3000');

    //     Evaluate(StartID, RangeParts.Get(1));
    //     Evaluate(EndID, RangeParts.Get(2));
    //     // Message('StartID:' + Format(StartID) + '  end:' + (Format(EndID)));
    //     SoumissionLine.SetRange("Soumission ID", SoumissionId);
    //     SoumissionLine.SetRange("Line No", StartID, EndID);
    //     Total := 0;
    //     if SoumissionLine.FindSet() then
    //         repeat
    //             if SoumissionLine.Type = SoumissionLine.Type::Formule then
    //                 continue;
    //             Total += SoumissionLine."Montant net";
    //         until SoumissionLine.Next() = 0;

    //     exit(Total);
    // end;

    procedure ProcessItemExtText(ItemNo: Code[20])
    var
        item: Record Item;
    begin
        if Rec.Type <> Rec.Type::Article then
            exit;
        if item.Get(Rec.No) then begin

            if item."Automatic Ext. Texts" = true then
                this.InsertItemExtText(rec.No);
        end;

    end;

    procedure CalculateTotalFromRange(CodeInput: Text[50]; SoumissionId: code[20]): Decimal
    var
        SoumissionLine: Record SoumissionLine;
        StartID: Integer;
        EndID: Integer;
        RangeParts: List of [Text];
        Sections: List of [Text];
        Section: Text;
        Total: Decimal;
        i: Integer;
    begin
        if CodeInput = '' then
            exit;

        // Split the input string by '|' to get individual sections
        Sections := CodeInput.Split('|');
        Total := 0;

        // Process each section
        for i := 1 to Sections.Count do begin
            Section := Sections.Get(i);

            // Split each section by '..' to get the range
            RangeParts := Section.Split('..');
            if RangeParts.Count <> 2 then
                Rec.FieldError(Totalisation, 'Invalid format, must be a range: e.g 1000..2000|5000..6000 or 1000..3000');

            Evaluate(StartID, RangeParts.Get(1));
            Evaluate(EndID, RangeParts.Get(2));

            // Calculate total for this range
            SoumissionLine.SetRange("Soumission ID", SoumissionId);
            SoumissionLine.SetRange("Line No", StartID, EndID);

            if SoumissionLine.FindSet() then
                repeat
                    if SoumissionLine.Type <> SoumissionLine.Type::Formule then
                        Total += SoumissionLine."Montant net";
                until SoumissionLine.Next() = 0;
        end;

        exit(Total);
    end;

    procedure InsertItemExtText(ItemNo: Code[20])
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        soumissionLine: Record SoumissionLine;
        LineNo: Integer;
        step: Integer;
    begin
        if isHandledExtItem then
            exit;

        if not Item.Get(ItemNo) then
            exit;

        soumissionLine.Reset();
        soumissionLine.SetRange("Soumission ID", Rec."Soumission ID");
        soumissionLine.SetRange(Type, soumissionLine.Type::Comment);
        soumissionLine.SetRange("Line No", Rec."Line No", Rec."Line No" + 10000);
        // if not soumissionLine.IsEmpty() then
        //     exit;
        soumissionLine.Reset();

        ExtendedTextHeader.Reset();
        ExtendedTextHeader.SetCurrentKey(
                  "Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
        ExtendedTextHeader.SetRange("Table Name", ExtendedTextHeader."Table Name"::Item);
        ExtendedTextHeader.SetRange("No.", ItemNo);
        ExtendedTextHeader.SetRange("Soumission", true);
        ExtendedTextHeader.SetRange("Starting Date", 0D, Today());
        ExtendedTextHeader.SetFilter("Ending Date", '%1..|%2', Today(), 0D);

        LineNo := Rec."Line No";
        step := 10000;
        soumissionLine.SetRange("Soumission ID", Rec."Soumission ID");
        soumissionLine.SetFilter("Line No", '>%1', Rec."Line No");
        soumissionLine.SetFilter("Type", '<>%1', soumissionLine.Type::Comment);
        if soumissionLine.FindFirst() then begin
            step := (soumissionLine."Line No" - Rec."Line No") div 100;
            if step < 1 then
                step := 1;
        end;
        soumissionLine.Reset();

        if ExtendedTextHeader.FindSet() then
            repeat
                ExtendedTextLine.Reset();
                ExtendedTextLine.SetRange("Table Name", ExtendedTextHeader."Table Name");
                ExtendedTextLine.SetRange("No.", ExtendedTextHeader."No.");
                ExtendedTextLine.SetRange("Text No.", ExtendedTextHeader."Text No.");
                if ExtendedTextLine.FindSet() then
                    repeat
                        LineNo += step;
                        if not soumissionLine.Get(Rec."Soumission ID", LineNo) then begin
                            soumissionLine.Init();
                            soumissionLine."Soumission ID" := Rec."Soumission ID";
                            soumissionLine."Line No" := LineNo;
                            soumissionLine.Insert();
                        end;
                        soumissionLine.Type := soumissionLine.Type::Comment;
                        soumissionLine.Designation := ExtendedTextLine.Text;
                        soumissionLine.Modify();
                    until ExtendedTextLine.Next() = 0;

            until ExtendedTextHeader.Next() = 0;
    end;

    procedure getSalesPriceListItemDetail()
    var
        Tempsalesline: Record "Sales Line" temporary;
        Salesline: Record "Sales Line";
        soumissionHeader: Record "SoumissionHeader";
        salesHeader: Record "Sales Header";
        salesHeadertoDelete: Record "Sales Header";
    begin
        if not soumissionHeader.Get(Rec."Soumission ID") then
            exit;

        if not salesHeader.Get(soumissionHeader."Document Type", soumissionHeader.DocumentNo) then begin
            salesHeader.Init();
            salesHeader."Document Type" := soumissionHeader."Document Type";
            salesHeader."No." := 'SoumissionCalc';
            salesHeader.Validate("Sell-to Customer No.", soumissionHeader."Customer ID");
            salesHeader.Insert();
            salesHeadertoDelete := salesHeader;

        end;

        Tempsalesline.Init();

        Salesline.Reset();
        Salesline.SetRange("Document Type", soumissionHeader."Document Type");
        Salesline.SetRange("No.", soumissionHeader.DocumentNo);
        // Salesline.SetRange("Line No.", Rec."Line No");
        if Salesline.FindLast() then begin
            Tempsalesline."Line No." := Salesline."Line No." + 10000;
        end else
            Tempsalesline."Line No." := 10000;

        Tempsalesline.SetHideValidationDialog(true);
        Tempsalesline."Document Type" := salesHeader."Document Type";
        Tempsalesline."Document No." := salesHeader."No.";
        Tempsalesline."No." := Rec.No;
        Tempsalesline.Validate("Sell-to Customer No.", soumissionHeader."Customer ID");
        Tempsalesline.Validate("Type", Tempsalesline.Type::Item);
        Tempsalesline.Validate("No.", Rec.No);
        if Rec.Quantity = 0 then
            Tempsalesline.Validate("Quantity", 1)
        else
            Tempsalesline.Validate("Quantity", Rec.Quantity);//quantity0
        Rec."Unit Price (base)" := Tempsalesline."Unit Price";
        Rec.Remise := Tempsalesline."Line Discount %";

        if salesHeadertoDelete."No." = 'SoumissionCalc' then
            if salesHeadertoDelete.Delete() then;
    end;

    procedure setIsHandledExtItem(isHandledExtItemVar: Boolean)
    begin
        isHandledExtItem := isHandledExtItemVar;
    end;

    procedure RenumberLines()
    var
        SoumissionLineBuffer: Record SoumissionLine;
        TempSoumissionLine: Record SoumissionLine temporary;
        TempLineNo: Integer;
        FinalLineNo: Integer;
        MaxLineNo: Integer;
    begin
        // Exit if Soumission ID is not set (during initialization)
        if Rec."Soumission ID" = '' then
            exit;

        // Step 1: Snapshot current line order into a temporary table
        SoumissionLineBuffer.Reset();
        SoumissionLineBuffer.SetLoadFields("Soumission ID", "Line No");
        SoumissionLineBuffer.SetRange("Soumission ID", Rec."Soumission ID");
        SoumissionLineBuffer.SetCurrentKey("Soumission ID", "Line No");
        if not SoumissionLineBuffer.FindSet() then
            exit;
        repeat
            TempSoumissionLine := SoumissionLineBuffer;
            TempSoumissionLine.Insert();
        until SoumissionLineBuffer.Next() = 0;

        // Step 2: Determine temp base = max existing Line No + 10000
        // After the loop, cursor is at last record, so capture MaxLineNo directly
        MaxLineNo := SoumissionLineBuffer."Line No";
        TempLineNo := MaxLineNo + 10000;

        // Step 3: Rename each real line to a temp number above the current max
        if TempSoumissionLine.FindSet() then
            repeat
                if SoumissionLineBuffer.Get(TempSoumissionLine."Soumission ID", TempSoumissionLine."Line No") then
                    SoumissionLineBuffer.Rename(SoumissionLineBuffer."Soumission ID", TempLineNo);
                TempLineNo += 10000;
            until TempSoumissionLine.Next() = 0;

        // Step 4: Rename from temp numbers to final sequential 10000, 20000, 30000, ...
        TempLineNo := MaxLineNo + 10000;
        FinalLineNo := 10000;
        if TempSoumissionLine.FindSet() then
            repeat
                if SoumissionLineBuffer.Get(TempSoumissionLine."Soumission ID", TempLineNo) then
                    if TempLineNo <> FinalLineNo then
                        SoumissionLineBuffer.Rename(SoumissionLineBuffer."Soumission ID", FinalLineNo);
                TempLineNo += 10000;
                FinalLineNo += 10000;
            until TempSoumissionLine.Next() = 0;
    end;

    var
        Soumission: Codeunit Soumission;
        isHandledExtItem: Boolean;
}