table 50100 RplpParametrage
{
    DataClassification = ToBeClassified;
    AllowInCustomizations = AsReadOnly;


    fields
    {
        field(1; "Code ID"; Integer)
        {
            // AutoIncrement = true;
            // NotBlank = true;
            MinValue = 1;
        }
        field(2; "Designation"; Text[100])
        {
            Caption = 'Désignation';
            NotBlank = true;
            trigger OnValidate()
            var
                item: Record Item;
            begin
                Rec.TestField(Article);
                item.get(Rec.Article);
                item.Description := Rec.Designation;
                item.Modify();
            end;
        }
        field(3; "Description"; Text[500])
        {

        }
        field(4; "Pourcentage RPLP"; Decimal)
        {
            NotBlank = true;
            BlankZero = true;
            MinValue = 0;
            trigger OnValidate()
            var
                item: Record Item;
            begin
                Rec.TestField(Article);
                item.get(Rec.Article);
                item."Unit Price" := Rec."Pourcentage RPLP" / 100;
                item.Modify();
            end;
        }
        field(5; "Date de debut"; Date)
        {
            Caption = 'Date de début';
            NotBlank = true;
        }
        field(6; "Date de fin"; Date)
        {
            NotBlank = true;
        }
        field(7; "Article"; Code[20])
        {
            TableRelation = Item."No." where(Type = const(Service));
            NotBlank = true;
            trigger OnValidate()
            var
                item: Record Item;
            begin
                Rec.TestField(Article);
                item.get(Rec.Article);
                item.Description := Rec.Designation;
                item."Unit Price" := Rec."Pourcentage RPLP" / 100;
                item.Modify();
            end;
        }
    }

    keys
    {
        key(Key1; "Code ID")
        {
            Clustered = true;
        }
        key(Key2; Article)
        {
            Unique = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
        fieldgroup(DropDown; "Code ID", Designation) { }
    }


    trigger OnInsert()
    begin
        if Rec."Code ID" = 0 then
            Error('Le code RPLP ne peut pas être égal à 0');
    end;

    trigger OnModify()
    begin
        if Rec."Code ID" = 0 then
            Error('Le code RPLP ne peut pas être égal à 0');
    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}