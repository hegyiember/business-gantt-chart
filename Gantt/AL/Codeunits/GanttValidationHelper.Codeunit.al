codeunit 71891732 "DGOG Gantt Validation Helper"
{
    procedure ValidateSetup(var GanttSetup: Record "DGOG Gantt Setup")
    var
        GanttView: Record "DGOG Gantt View";
        MappingLine: Record "DGOG Gantt Mapping Line";
    begin
        if not GanttSetup.Active then
            Error('Gantt setup %1 is not active.', GanttSetup."ID");

        GanttView.SetRange("Setup ID", GanttSetup."ID");
        if not GanttView.FindFirst() then
            Error('Gantt setup %1 must contain at least one view.', GanttSetup."ID");

        repeat
            ValidateView(GanttSetup, GanttView);
        until GanttView.Next() = 0;

        MappingLine.SetRange("Setup ID", GanttSetup."ID");
        if not MappingLine.FindFirst() then
            Error('Gantt setup %1 must contain at least one mapping line.', GanttSetup."ID");
    end;

    procedure ValidateView(GanttSetup: Record "DGOG Gantt Setup"; GanttView: Record "DGOG Gantt View")
    var
        MappingLine: Record "DGOG Gantt Mapping Line";
        DetailLine: Record "DGOG Gantt Detail Line";
    begin
        MappingLine.SetRange("Setup ID", GanttSetup."ID");
        MappingLine.SetRange("View Code", GanttView."View Code");
        if not MappingLine.FindFirst() then
            Error('View %1 on setup %2 does not contain any mapping lines.', GanttView."View Code", GanttSetup."ID");

        repeat
            ValidateMappingLine(MappingLine);
        until MappingLine.Next() = 0;

        DetailLine.SetRange("Setup ID", GanttSetup."ID");
        DetailLine.SetRange("View Code", GanttView."View Code");
        if DetailLine.FindSet() then
            repeat
                ValidateDetailLine(DetailLine);
            until DetailLine.Next() = 0;
    end;

    procedure ValidateMappingLine(MappingLine: Record "DGOG Gantt Mapping Line")
    begin
        EnsureTableExists(MappingLine."Source Table ID");
        EnsureFieldExists(MappingLine."Source Table ID", MappingLine."Key Field ID");
        EnsureParentRelationIfSpecified(MappingLine);

        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Description Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Start Date Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."End Date Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Due Date Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Start Decimal Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."End Decimal Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Status Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Sequence Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Grouping Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Context Identity Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Resource Group Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Dependency Source Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Dependency Target Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Dependency Type Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Aggregation Value Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Aggregation Capacity Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Conflict Group Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Progress Override Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Color Override Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Label Override Field ID");
        EnsureFieldIfSpecified(MappingLine."Source Table ID", MappingLine."Tooltip Title Field ID");
    end;

    procedure ValidateDetailLine(DetailLine: Record "DGOG Gantt Detail Line")
    var
        MappingLine: Record "DGOG Gantt Mapping Line";
    begin
        if not MappingLine.Get(DetailLine."Setup ID", DetailLine."View Code", DetailLine."Mapping Line No.") then
            Error('Detail line %1 references missing mapping line %2 in view %3 setup %4.', DetailLine."Line No.", DetailLine."Mapping Line No.", DetailLine."View Code", DetailLine."Setup ID");

        EnsureFieldExists(MappingLine."Source Table ID", DetailLine."Field ID");
    end;

    procedure ResolveViewCode(SetupId: Integer; RequestedViewCode: Code[20]): Code[20]
    var
        GanttSetup: Record "DGOG Gantt Setup";
        GanttView: Record "DGOG Gantt View";
    begin
        if RequestedViewCode <> '' then
            exit(RequestedViewCode);

        GanttSetup.Get(SetupId);
        if GanttSetup."Default View Code" <> '' then
            exit(GanttSetup."Default View Code");

        GanttView.SetRange("Setup ID", SetupId);
        GanttView.SetRange("Is Default", true);
        if GanttView.FindFirst() then
            exit(GanttView."View Code");

        GanttView.SetRange("Is Default");
        if GanttView.FindFirst() then
            exit(GanttView."View Code");

        exit('');
    end;

    procedure EnsureTableExists(TableId: Integer)
    var
        AllObjects: Record AllObjWithCaption;
    begin
        if TableId = 0 then
            Error('A source table ID is required.');

        AllObjects.SetRange("Object Type", AllObjects."Object Type"::Table);
        AllObjects.SetRange("Object ID", TableId);
        if not AllObjects.FindFirst() then
            Error('Table %1 does not exist or is not accessible.', TableId);
    end;

    procedure EnsureFieldExists(TableId: Integer; FieldId: Integer)
    var
        FieldMeta: Record Field;
    begin
        if FieldId = 0 then
            Error('A required field ID is missing for table %1.', TableId);
        if not FieldMeta.Get(TableId, FieldId) then
            Error('Field %1 does not exist on table %2.', FieldId, TableId);
    end;

    procedure EnsureFieldIfSpecified(TableId: Integer; FieldId: Integer)
    begin
        if FieldId = 0 then
            exit;
        EnsureFieldExists(TableId, FieldId);
    end;

    procedure EnsureParentRelationIfSpecified(MappingLine: Record "DGOG Gantt Mapping Line")
    var
        ParentMappingLine: Record "DGOG Gantt Mapping Line";
        ChildFieldMeta: Record Field;
        ParentFieldMeta: Record Field;
    begin
        if MappingLine."Parent Line No." = 0 then begin
            if MappingLine."Relation Field ID" <> 0 then
                Error('Relation Field ID must be blank on root mapping line %1.', MappingLine."Line No.");
            exit;
        end;

        if MappingLine."Relation Field ID" = 0 then
            Error('Relation Field ID is required on non-root mapping line %1.', MappingLine."Line No.");

        if not ParentMappingLine.Get(MappingLine."Setup ID", MappingLine."View Code", MappingLine."Parent Line No.") then
            Error('Parent mapping line %1 does not exist for mapping line %2.', MappingLine."Parent Line No.", MappingLine."Line No.");

        EnsureFieldExists(MappingLine."Source Table ID", MappingLine."Relation Field ID");
        EnsureFieldExists(ParentMappingLine."Source Table ID", ParentMappingLine."Key Field ID");

        ChildFieldMeta.Get(MappingLine."Source Table ID", MappingLine."Relation Field ID");
        ParentFieldMeta.Get(ParentMappingLine."Source Table ID", ParentMappingLine."Key Field ID");

        if ChildFieldMeta.Type <> ParentFieldMeta.Type then
            Error(
              'Relation field %1 on table %2 must have the same type as parent key field %3 on table %4.',
              MappingLine."Relation Field ID",
              MappingLine."Source Table ID",
              ParentMappingLine."Key Field ID",
              ParentMappingLine."Source Table ID");
    end;

    procedure HasField(TableId: Integer; FieldId: Integer): Boolean
    var
        FieldMeta: Record Field;
    begin
        if (TableId = 0) or (FieldId = 0) then
            exit(false);
        exit(FieldMeta.Get(TableId, FieldId));
    end;

    procedure GetFieldCaption(TableId: Integer; FieldId: Integer): Text
    var
        FieldMeta: Record Field;
    begin
        if not FieldMeta.Get(TableId, FieldId) then
            exit(Format(FieldId));
        exit(FieldMeta."Field Caption");
    end;

    procedure GetFieldValueAsText(var SourceRef: RecordRef; FieldId: Integer): Text
    var
        SourceField: FieldRef;
    begin
        if FieldId = 0 then
            exit('');
        SourceField := SourceRef.Field(FieldId);
        exit(Format(SourceField.Value, 0, 9));
    end;

    procedure GetFieldValueAsIso(var SourceRef: RecordRef; FieldId: Integer): Text
    var
        FieldMeta: Record Field;
        SourceField: FieldRef;
        DateValue: Date;
        DateTimeValue: DateTime;
        TimeValue: Time;
    begin
        if FieldId = 0 then
            exit('');
        SourceField := SourceRef.Field(FieldId);
        if not FieldMeta.Get(SourceRef.Number, FieldId) then
            exit(Format(SourceField.Value, 0, 9));

        case FieldMeta.Type of
            FieldMeta.Type::Date:
                begin
                    DateValue := SourceField.Value;
                    if DateValue = 0D then
                        exit('');
                    exit(Format(CreateDateTime(DateValue, 0T), 0, 9));
                end;
            FieldMeta.Type::DateTime:
                begin
                    DateTimeValue := SourceField.Value;
                    if DateTimeValue = 0DT then
                        exit('');
                    exit(Format(DateTimeValue, 0, 9));
                end;
            FieldMeta.Type::Time:
                begin
                    TimeValue := SourceField.Value;
                    exit(Format(CreateDateTime(Today, TimeValue), 0, 9));
                end;
            else
                exit(Format(SourceField.Value, 0, 9));
        end;
    end;

    procedure GetFieldDateTime(var SourceRef: RecordRef; FieldId: Integer): DateTime
    var
        FieldMeta: Record Field;
        SourceField: FieldRef;
        DateValue: Date;
        DateTimeValue: DateTime;
        TimeValue: Time;
    begin
        if FieldId = 0 then
            exit(0DT);
        SourceField := SourceRef.Field(FieldId);
        if not FieldMeta.Get(SourceRef.Number, FieldId) then
            exit(0DT);

        case FieldMeta.Type of
            FieldMeta.Type::Date:
                begin
                    DateValue := SourceField.Value;
                    if DateValue = 0D then
                        exit(0DT);
                    exit(CreateDateTime(DateValue, 0T));
                end;
            FieldMeta.Type::DateTime:
                begin
                    DateTimeValue := SourceField.Value;
                    exit(DateTimeValue);
                end;
            FieldMeta.Type::Time:
                begin
                    TimeValue := SourceField.Value;
                    exit(CreateDateTime(Today, TimeValue));
                end;
        end;

        exit(0DT);
    end;

    procedure GetFieldDecimal(var SourceRef: RecordRef; FieldId: Integer): Decimal
    var
        SourceField: FieldRef;
        DecimalValue: Decimal;
    begin
        if FieldId = 0 then
            exit(0);
        SourceField := SourceRef.Field(FieldId);
        Evaluate(DecimalValue, Format(SourceField.Value, 0, 9));
        exit(DecimalValue);
    end;

    procedure SetFieldFromText(var SourceRef: RecordRef; FieldId: Integer; NewValueText: Text)
    var
        FieldMeta: Record Field;
        TargetField: FieldRef;
        DateValue: Date;
        DateTimeValue: DateTime;
        DecimalValue: Decimal;
        IntegerValue: Integer;
        BigIntegerValue: BigInteger;
        TimeValue: Time;
        BooleanValue: Boolean;
    begin
        EnsureFieldExists(SourceRef.Number, FieldId);
        FieldMeta.Get(SourceRef.Number, FieldId);
        TargetField := SourceRef.Field(FieldId);

        case FieldMeta.Type of
            FieldMeta.Type::Date:
                begin
                    Clear(DateValue);
                    if NewValueText <> '' then
                        Evaluate(DateValue, NewValueText);
                    TargetField.Validate(DateValue);
                end;
            FieldMeta.Type::DateTime:
                begin
                    Clear(DateTimeValue);
                    if NewValueText <> '' then
                        Evaluate(DateTimeValue, NewValueText);
                    TargetField.Validate(DateTimeValue);
                end;
            FieldMeta.Type::Time:
                begin
                    Clear(TimeValue);
                    if NewValueText <> '' then
                        Evaluate(TimeValue, NewValueText);
                    TargetField.Validate(TimeValue);
                end;
            FieldMeta.Type::Decimal:
                begin
                    Clear(DecimalValue);
                    if NewValueText <> '' then
                        Evaluate(DecimalValue, NewValueText);
                    TargetField.Validate(DecimalValue);
                end;
            FieldMeta.Type::Integer:
                begin
                    Clear(IntegerValue);
                    if NewValueText <> '' then
                        Evaluate(IntegerValue, NewValueText);
                    TargetField.Validate(IntegerValue);
                end;
            FieldMeta.Type::BigInteger:
                begin
                    Clear(BigIntegerValue);
                    if NewValueText <> '' then
                        Evaluate(BigIntegerValue, NewValueText);
                    TargetField.Validate(BigIntegerValue);
                end;
            FieldMeta.Type::Boolean:
                begin
                    Clear(BooleanValue);
                    if NewValueText <> '' then
                        Evaluate(BooleanValue, NewValueText);
                    TargetField.Validate(BooleanValue);
                end;
            else
                TargetField.Validate(NewValueText);
        end;
    end;

    procedure SetFieldFilterFromText(var SourceRef: RecordRef; FieldId: Integer; FilterText: Text)
    var
        FieldMeta: Record Field;
        SourceField: FieldRef;
        DateValue: Date;
        DateTimeValue: DateTime;
        DecimalValue: Decimal;
        IntegerValue: Integer;
        BigIntegerValue: BigInteger;
        TimeValue: Time;
    begin
        if (FieldId = 0) or (FilterText = '') then
            exit;

        FieldMeta.Get(SourceRef.Number, FieldId);
        SourceField := SourceRef.Field(FieldId);

        case FieldMeta.Type of
            FieldMeta.Type::Date:
                begin
                    Evaluate(DateValue, FilterText);
                    SourceField.SetRange(DateValue);
                end;
            FieldMeta.Type::DateTime:
                begin
                    Evaluate(DateTimeValue, FilterText);
                    SourceField.SetRange(DateTimeValue);
                end;
            FieldMeta.Type::Time:
                begin
                    Evaluate(TimeValue, FilterText);
                    SourceField.SetRange(TimeValue);
                end;
            FieldMeta.Type::Decimal:
                begin
                    Evaluate(DecimalValue, FilterText);
                    SourceField.SetRange(DecimalValue);
                end;
            FieldMeta.Type::Integer:
                begin
                    Evaluate(IntegerValue, FilterText);
                    SourceField.SetRange(IntegerValue);
                end;
            FieldMeta.Type::BigInteger:
                begin
                    Evaluate(BigIntegerValue, FilterText);
                    SourceField.SetRange(BigIntegerValue);
                end;
            else
                SourceField.SetRange(FilterText);
        end;
    end;
}