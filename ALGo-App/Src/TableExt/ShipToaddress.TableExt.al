tableextension 50111 ShipToAddress extends "Ship-to Address"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50100; Dataverse_PostCode; Code[20])
        {
            trigger OnValidate()
            begin
                Rec."Post Code" := Rec.Dataverse_PostCode;
                Rec.Validate("Post Code");

            end;
        }
        field(50104; msdyn_FunctionalLocationId; GUID)
        {
            Caption = 'CDS msdyn_FunctionalLocationId';
            DataClassification = CustomerContent;
            Description = 'Identificateur unique des instances d’entité';
        }
        modify("Post Code")
        {
            trigger OnAfterValidate()
            begin
                Rec.Dataverse_PostCode := Rec."Post Code";
                // Rec.Validate(City);

            end;
        }

        field(50101; Dataverse_City; Text[30])
        {
            trigger OnValidate()
            begin
                Rec.City := Rec.Dataverse_City;
                Rec.Validate(City);

            end;
        }
        modify(City)
        {
            trigger OnAfterValidate()
            begin
                Rec.Dataverse_City := Rec.City;

            end;
        }

        field(50102; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Field Service';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Ship-to Address")));
        }

        field(50103; "Dataverse_Country/Region Code"; Code[10])
        {
            trigger OnValidate()
            begin
                Rec."Country/Region Code" := Rec."Dataverse_Country/Region Code";
                Rec.Validate(City);

            end;
        }
        modify("Country/Region Code")
        {
            trigger OnAfterValidate()
            begin
                Rec."Dataverse_Country/Region Code" := Rec."Country/Region Code";

            end;
        }
    }

    fieldgroups
    {
        addlast(DropDown; "Coupled to Dataverse") { }
        addlast(Brick; "Coupled to Dataverse") { }
    }
    //in
}