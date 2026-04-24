/**
 * @description       : Base class for all Selector classes
 * @author            : 
 * @group             : 
 * @last modified on  : 2026-04-23
 * @last modified by  : 
**/
public abstract inherited sharing class BaseSelector {

    /**
     * @description Returns the SObjectType this Selector works with
     */
    public abstract Schema.SObjectType getSObjectType();

    /**
     * @description Returns the default list of fields to query
     */
    public abstract List<Schema.SObjectField> getSObjectFieldList();

    /**
     * @description Instantiates a new SOQLBuilder with default fields and SObjectType
     */
    protected virtual SOQLBuilder newQueryBuilder() {
        SOQLBuilder builder = new SOQLBuilder(getSObjectType());
        List<String> fieldNames = new List<String>();
        for (Schema.SObjectField field : getSObjectFieldList()) {
            fieldNames.add(field.getDescribe().getName());
        }
        builder.selectFields(fieldNames);
        builder.withSecurityEnforced();
        return builder;
    }

    /**
     * @description Inner class to handle query configuration from Service Layer
     */
    public class QueryConfig {
        public List<Schema.FieldSet> fieldSets { get; private set; }
        public List<String> additionalFields { get; private set; }
        public String orderByClause { get; private set; }
        public Integer limitCount { get; private set; }
        public Integer offsetCount { get; private set; }
        public Boolean enforceUserMode { get; private set; }

        public QueryConfig() {
            this.fieldSets = new List<Schema.FieldSet>();
            this.additionalFields = new List<String>();
            this.enforceUserMode = false;
        }

        public QueryConfig withFieldSet(Schema.FieldSet fs) {
            if (fs != null) {
                this.fieldSets.add(fs);
            }
            return this;
        }

        public QueryConfig withAdditionalField(String fieldPath) {
            if (String.isNotBlank(fieldPath)) {
                this.additionalFields.add(fieldPath);
            }
            return this;
        }

        public QueryConfig withAdditionalFields(List<String> fields) {
            if (fields != null) {
                this.additionalFields.addAll(fields);
            }
            return this;
        }

        public QueryConfig withOrderBy(String orderBy) {
            this.orderByClause = orderBy;
            return this;
        }

        public QueryConfig withLimit(Integer limitCount) {
            this.limitCount = limitCount;
            return this;
        }

        public QueryConfig withOffset(Integer offsetCount) {
            this.offsetCount = offsetCount;
            return this;
        }

        public QueryConfig withUserMode() {
            this.enforceUserMode = true;
            return this;
        }
    }

    /**
     * @description Apply QueryConfig to a SOQLBuilder
     */
    protected virtual SOQLBuilder applyConfig(SOQLBuilder builder, QueryConfig config) {
        if (config == null) return builder;

        if (!config.fieldSets.isEmpty()) {
            for (Schema.FieldSet fs : config.fieldSets) {
                builder.selectFields(fs);
            }
        }

        if (!config.additionalFields.isEmpty()) {
            builder.selectFields(config.additionalFields);
        }

        if (String.isNotBlank(config.orderByClause)) {
            builder.orderBy(config.orderByClause);
        }

        if (config.limitCount != null) {
            builder.setLimit(config.limitCount);
        }

        if (config.offsetCount != null) {
            builder.setOffset(config.offsetCount);
        }

        if (config.enforceUserMode) {
            builder.withUserMode();
        }

        return builder;
    }

    /**
     * @description Default method to select by Ids
     */
    public virtual List<SObject> selectById(Set<Id> ids) {
        return selectById(ids, null);
    }

    /**
     * @description Select by Ids with dynamic configuration
     */
    public virtual List<SObject> selectById(Set<Id> ids, QueryConfig config) {
        if (ids == null || ids.isEmpty()) {
            return new List<SObject>();
        }

        try {
            SOQLBuilder builder = newQueryBuilder();
            applyConfig(builder, config);
            
            // Format Ids to string for the query because Database.query is executed inside SOQLBuilder
            // Bind variables would be out of scope.
            List<String> idStrings = new List<String>();
            for(Id idValue : ids) {
                idStrings.add('\'' + String.escapeSingleQuotes((String)idValue) + '\'');
            }
            String inClause = '(' + String.join(idStrings, ',') + ')';
            
            builder.whereCondition('Id IN ' + inClause);

            return builder.execute();
        } catch (Exception ex) {
            LoggerUtils.error(ex.getMessage(), ex.getStackTraceString(), 'BaseSelector.selectById', null);
            throw ex;
        }
    }

    /**
     * @description Sanitizes input to prevent SOQL injection
     */
    public static String sanitize(String input) {
        return String.isBlank(input) ? input : String.escapeSingleQuotes(input);
    }

    /**
     * @description       : Framework to build dynamic SOQL using Builder Pattern
     */
    public class SOQLBuilder {
        private Set<String> selectFields;
        private String sObjectName;
        private List<String> whereConditions;
        private String orderByClause;
        private Integer limitCount;
        private Integer offsetCount;
        private Boolean isSecurityEnforced;
        private Boolean isUserMode;

        public SOQLBuilder(String sObjectName) {
            this.sObjectName = sObjectName;
            this.selectFields = new Set<String>();
            this.whereConditions = new List<String>();
            this.isSecurityEnforced = false;
            this.isUserMode = false;
        }

        public SOQLBuilder(Schema.SObjectType sObjectType) {
            this(sObjectType.getDescribe().getName());
        }

        public SOQLBuilder selectField(String field) {
            if (String.isNotBlank(field)) {
                this.selectFields.add(field.trim());
            }
            return this;
        }

        public SOQLBuilder selectFields(String fields) {
            if (String.isNotBlank(fields)) {
                for (String f : fields.split(',')) {
                    if (String.isNotBlank(f)) {
                        this.selectFields.add(f.trim());
                    }
                }
            }
            return this;
        }

        public SOQLBuilder selectFields(List<String> fields) {
            if (fields != null) {
                for (String f : fields) {
                    if (String.isNotBlank(f)) {
                        this.selectFields.add(f.trim());
                    }
                }
            }
            return this;
        }

        public SOQLBuilder selectFields(Set<String> fields) {
            if (fields != null) {
                for (String f : fields) {
                    if (String.isNotBlank(f)) {
                        this.selectFields.add(f.trim());
                    }
                }
            }
            return this;
        }

        public SOQLBuilder selectFields(Schema.FieldSet fieldSet) {
            if (fieldSet != null) {
                for (Schema.FieldSetMember fsm : fieldSet.getFields()) {
                    this.selectFields.add(fsm.getFieldPath());
                }
            }
            return this;
        }

        public SOQLBuilder selectSubQuery(SOQLBuilder subQueryBuilder) {
            if (subQueryBuilder != null) {
                this.selectFields.add('(' + subQueryBuilder.build() + ')');
            }
            return this;
        }

        public SOQLBuilder whereCondition(String condition) {
            if (String.isNotBlank(condition)) {
                this.whereConditions.add(condition.trim());
            }
            return this;
        }

        public SOQLBuilder orderBy(String orderByClause) {
            this.orderByClause = orderByClause;
            return this;
        }

        public SOQLBuilder setLimit(Integer limitCount) {
            this.limitCount = limitCount;
            return this;
        }

        public SOQLBuilder setOffset(Integer offsetCount) {
            this.offsetCount = offsetCount;
            return this;
        }

        public SOQLBuilder withSecurityEnforced() {
            this.isSecurityEnforced = true;
            return this;
        }

        public SOQLBuilder withUserMode() {
            this.isUserMode = true;
            return this;
        }

        public String build() {
            String query = 'SELECT ';
            if (this.selectFields.isEmpty()) {
                query += 'Id';
            } else {
                List<String> fieldsList = new List<String>(this.selectFields);
                query += String.join(fieldsList, ', ');
            }

            query += ' FROM ' + this.sObjectName;

            if (!this.whereConditions.isEmpty()) {
                query += ' WHERE ' + String.join(this.whereConditions, ' AND ');
            }

            if (this.isSecurityEnforced && !this.isUserMode) {
                query += ' WITH SECURITY_ENFORCED';
            }

            if (String.isNotBlank(this.orderByClause)) {
                query += ' ORDER BY ' + this.orderByClause;
            }

            if (this.limitCount != null) {
                query += ' LIMIT ' + this.limitCount;
            }

            if (this.offsetCount != null) {
                query += ' OFFSET ' + this.offsetCount;
            }

            return query;
        }

        public List<SObject> execute() {
            String query = build();
            if (this.isUserMode) {
                return Database.query(query, AccessLevel.USER_MODE);
            } else {
                return Database.query(query);
            }
        }
    }
}