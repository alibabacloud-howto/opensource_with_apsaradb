import ast
import csv
import numpy
import pandas
import pycountry

import luigi
import luigi.contrib.target
import luigi.contrib.postgres

from mlxtend.frequent_patterns import apriori
from mlxtend.preprocessing import TransactionEncoder
from mlxtend.frequent_patterns import association_rules


class Config(luigi.Config):
    """
    Luigi configuration file containing information such as PostgreSQL connection details, database table names etc
    """
    date = luigi.DateParameter()

    host = 'localhost'
    port = '1921'
    database = 'sales_dw'
    user = 'demo'
    password = 'N1cetest'

    customer_info_table = 'customer_info'
    invoice_table = 'invoice'
    invoice_time_table = 'invoice_time'
    product_info_table = 'product_info'
    association_rules_table = 'association_rules'
    outliers_table = 'invoice_outliers'

    column_separator = "\t"


class DataDump(luigi.ExternalTask):
    """
    This is an external data dump task.

    This task is the top of the dependency graph and will only be successful if the data dump is available.
    """
    date = luigi.DateParameter()

    def output(self):
        """
        Returns the target output for this task.
        In this case, it expects a csv file to be present in data directory

        :return: list of target output containing csv files.
        :rtype: object (:py:class:`luigi.target.Target`)
        """
        return [luigi.LocalTarget(self.date.strftime("data/%Y_%m_%d" + "/" + Config.customer_info_table + ".csv")),
                luigi.LocalTarget(self.date.strftime("data/%Y_%m_%d" + "/" + Config.invoice_table + ".csv")),
                luigi.LocalTarget(self.date.strftime("data/%Y_%m_%d" + "/" + Config.product_info_table + ".csv"))]


class CustomerInfoPreProcessing(luigi.Task):
    """
    This task perform data cleansing and transformations on the customer_info table's csv file.

    It will also add column named called Country_Code, which will be used in data insights dashboard.
    """
    date = luigi.DateParameter()

    def requires(self):
        """
        This task depends on the DataDump task.
        """
        return DataDump(self.date)

    def run(self):
        """
        This function picks up the csv containing customer information, and perform data cleansing and transformations.

        It will also add Country_Code column. Output will be written in intermediate csv file.
        """
        data = pandas.read_csv(self.input()[0].path)

        data.country.fillna("Not Available", inplace=True)
        data.country = data.country.str.strip().str.title()

        countries = dict()
        for country in pycountry.countries:
            countries[country.name] = country.alpha_2

        data['Country_Code'] = data.country.map(countries)
        data.rename(columns={"customerid": "customer_id", "country": "country_name"}, inplace=True)

        data.to_csv(self.input()[0].path + "_processed", encoding="utf-8", header=False, index=None)

    def output(self):
        """
        Returns the csv file as target to be loaded into database.

        :return: target output containing csv files.
        :rtype: object (:py:class:`luigi.target.Target`)
        """
        return luigi.LocalTarget(self.input()[0].path + "_processed")


class InvoicePreProcessing(luigi.Task):
    """
    This task perform data cleansing and transformations on the invoice table's csv file.
    """
    date = luigi.DateParameter()

    def requires(self):
        """
        This task depends on the DataDump task.
        """
        return DataDump(self.date)

    def run(self):
        """
        This function picks up the csv containing invoice information, and perform data cleansing and transformations.
        """
        data = pandas.read_csv(self.input()[1].path)
        data.invoicedate = pandas.to_datetime(data.invoicedate)
        data.rename(columns={"invoiceno": "invoice_no", "stockcode": "stock_code",
                             "invoicedate": "invoice_date", "customerid": "customer_id"}, inplace=True)

        data.to_csv(self.input()[1].path + "_processed", encoding="utf-8", header=False, index=None)

    def output(self):
        """
        Returns the csv file as target to be loaded into database.

        :return: target output containing csv files.
        :rtype: object (:py:class:`luigi.target.Target`)
        """
        return luigi.LocalTarget(self.input()[1].path + "_processed")


class InvoiceTimeGeneration(luigi.Task):
    """
    This task will divide invoice_date column from invoice table's csv file, into separate columns such as Day,
    Week, Quarter, Year etc.

    This will be helpful in performing data analytics.
    """
    date = luigi.DateParameter()

    def requires(self):
        """
        This task depends on the DataDump task.
        """
        return DataDump(self.date)

    def run(self):
        """
        This function picks up invoice_date column from invoice csv file.

        Date will be further broken down in to columns such as Day, Week, Quarter, Year etc., and will be written in
        separate csv file.
        """
        data = pandas.read_csv(self.input()[1].path)

        data.invoicedate = pandas.to_datetime(data.invoicedate)
        data_splitted = pandas.DataFrame({
            "invoice_date": data.invoicedate,
            "dayofweek": data.invoicedate.dt.dayofweek,
            "year": data.invoicedate.dt.year,
            "month": data.invoicedate.dt.month,
            "day": data.invoicedate.dt.day,
            "hour": data.invoicedate.dt.hour,
            "minute": data.invoicedate.dt.minute,
            "dayofyear": data.invoicedate.dt.dayofyear,
            "week": data.invoicedate.dt.week,
            "quarter": data.invoicedate.dt.quarter
        })

        data_splitted.to_csv(self.input()[1].path + "_time", sep="\t", encoding="utf-8", header=False, index=None)

    def output(self):
        """
        Returns the csv file as target to be loaded into database.

        :return: target output containing csv files.
        :rtype: object (:py:class:`luigi.target.Target`)
        """
        return luigi.LocalTarget(self.input()[1].path + "_time")


class ProductInfoPreProcessing(luigi.Task):
    """
    This task perform data cleansing and transformations on the product_info table's csv file.
    """
    date = luigi.DateParameter()

    def requires(self):
        """
        This task depends on the DataDump task.
        """
        return DataDump(self.date)

    def run(self):
        """
        This function will pick up csv file and perform data cleansing and transformations.

        It will remove extra whitespaces from description column. Finally, will load data into intermediate csv file.
        """
        data = pandas.read_csv(self.input()[2].path)

        data.description.replace('\s+', ' ', regex=True, inplace=True)
        data.description = data.description.str.strip()
        data.rename(columns={"stockcode": "stock_code", "unitprice": "unit_price"}, inplace=True)

        data.to_csv(self.input()[2].path + "_processed", sep="\t", encoding="utf-8", header=False, index=None)

    def output(self):
        """
        Returns the csv file as target to be loaded into database.

        :return: target output containing csv files.
        :rtype: object (:py:class:`luigi.target.Target`)
        """
        return luigi.LocalTarget(self.input()[2].path + "_processed")


class CustomerInfoLoading(luigi.contrib.postgres.CopyToTable):
    """
    This task will load csv file into Postgres table.
    """
    date = luigi.DateParameter()

    host = Config.host
    port = Config.port
    database = Config.database
    user = Config.user
    password = Config.password
    table = Config.customer_info_table
    column_separator = ","

    columns = [("customer_id", "INT"),
               ("country", "TEXT"),
               ("country_code", "TEXT")]

    def requires(self):
        """
        This task depends on customer_info csv cleaning task
        """
        return CustomerInfoPreProcessing(self.date)


class InvoiceLoading(luigi.contrib.postgres.CopyToTable):
    """
    This task will load csv file into Postgres table.
    """
    date = luigi.DateParameter()

    host = Config.host
    port = Config.port
    database = Config.database
    user = Config.user
    password = Config.password
    table = Config.invoice_table
    column_separator = ","

    columns = [("invoice_no", "TEXT"),
               ("stock_code", "TEXT"),
               ("quantity", "INT"),
               ("invoice_date", "TEXT"),
               ("customer_id", "INT")]

    def requires(self):
        """
        This task depends on invoice csv cleaning task
        """
        return InvoicePreProcessing(self.date)


class InvoiceTimeLoading(luigi.contrib.postgres.CopyToTable):
    """
    This task will load csv file into Postgres table.
    """
    date = luigi.DateParameter()

    host = Config.host
    port = Config.port
    database = Config.database
    user = Config.user
    password = Config.password
    table = Config.invoice_time_table
    column_separator = "\t"

    columns = [("invoice_date", "TEXT"),
               ("dayofweek", "INT"),
               ("year", "INT"),
               ("month", "TEXT"),
               ("day", "INT"),
               ("hour", "INT"),
               ("minute", "INT"),
               ("dayofyear", "INT"),
               ("weekofyear", "INT"),
               ("quarter", "INT")]

    def requires(self):
        """
        This task depends on invoice_time csv generation task
        """
        return InvoiceTimeGeneration(self.date)


class ProductInfoLoading(luigi.contrib.postgres.CopyToTable):
    """
    This task will load csv file into Postgres table.
    """
    date = luigi.DateParameter()

    host = Config.host
    port = Config.port
    database = Config.database
    user = Config.user
    password = Config.password
    table = Config.product_info_table
    column_separator = "\t"

    columns = [("stock_code", "TEXT"),
               ("description", "TEXT"),
               ("unit_price", "FLOAT")]

    def requires(self):
        """
        This task depends on product_info csv cleaning task
        """
        return ProductInfoPreProcessing(self.date)


class AssociationRulesGeneration(luigi.Task):
    """
    This task will generate association rules i.e. customers who have bought this, also bought this.

    This will help business owner to launch bundle offers.

    Further extension can be made to check what items are being returned frequently.
    """
    date = luigi.DateParameter()

    def requires(self):
        """
        This task will execute once all previous csv files are loaded into the database.
        """
        return [CustomerInfoLoading(self.date),
                InvoiceLoading(self.date),
                ProductInfoLoading(self.date),
                InvoiceTimeLoading(self.date)]

    def run(self):
        """
        Apriori algorithm will be used in order to generate association rules.
        """
        data = pandas.read_csv(self.date.strftime("data/%Y_%m_%d" + "/" + Config.invoice_table + ".csv"))

        grouped = data[['customerid', 'stockcode']].groupby('customerid')
        aggregated_data = grouped.aggregate(lambda x: list(x))
        aggregated_data.to_csv(self.date.strftime("data/%Y_%m_%d" + "/" + Config.invoice_table + ".csv_aggregated"),
                               encoding="utf-8", header=False, index=None)

        temp = list()
        with open(self.date.strftime("data/%Y_%m_%d" + "/" + Config.invoice_table + ".csv_aggregated"), 'r') as f:
            for row in csv.reader(f):
                eval_temp = ast.literal_eval(''.join(row))
                if len(eval_temp) == 1:
                    continue
                temp.append(eval_temp)

        te = TransactionEncoder()
        te_ary = te.fit(temp).transform(temp)
        df = pandas.DataFrame(te_ary, columns=te.columns_)
        frequent_itemsets = apriori(df, min_support=0.05, use_colnames=True)
        association_rules(frequent_itemsets, metric="confidence", min_threshold=0.7)
        rules = association_rules(frequent_itemsets, metric="lift", min_threshold=1.2)

        final_rules = pandas.DataFrame([rules['antecedents'].str.join(''),
                                        rules['consequents'].str.join(''),
                                        rules['antecedent support'],
                                        rules['consequent support'],
                                        rules['support'],
                                        rules['confidence'],
                                        rules['lift'],
                                        rules['leverage'],
                                        rules['conviction']]).T

        final_rules.to_csv(self.date.strftime("data/%Y_%m_%d" + "/" + Config.invoice_table + ".csv_association_rules"),
                           encoding="utf-8", header=False, index=None)

    def output(self):
        """
        Returns the csv file as target to be loaded into database.

        :return: target output containing csv files.
        :rtype: object (:py:class:`luigi.target.Target`)
        """
        return luigi.LocalTarget(
            self.date.strftime("data/%Y_%m_%d" + "/" + Config.invoice_table + ".csv_association_rules"))


class OutliersDetection(luigi.Task):
    """
    This task will pick up invoice table csv and perform Tukey's IQR outlier detection algorithm on the data.
    """
    date = luigi.DateParameter()

    def requires(self):
        """
        This task will execute once all previous csv files are loaded into the database.
        """
        return [CustomerInfoLoading(self.date),
                InvoiceLoading(self.date),
                ProductInfoLoading(self.date),
                InvoiceTimeLoading(self.date)]

    def run(self):
        """
        Tukey's IQR will be used to detect outliers/anomalies.

        We have only performed this on quantity column as a demonstration purpose.

        More fields can be added to widen the search for anomalies.
        """
        data = pandas.read_csv(self.date.strftime("data/%Y_%m_%d" + "/" + Config.invoice_table + ".csv"))

        quantity = data['quantity']
        q75, q25 = numpy.percentile(quantity, [75, 25])
        iqr = q75 - q25
        upper_fence = q75 + (30.0 * iqr)
        outliers = data[data.quantity > upper_fence]

        outliers.to_csv(self.date.strftime("data/%Y_%m_%d" + "/" + Config.invoice_table + ".csv_outliers"),
                        encoding="utf-8", header=False, index=None)

    def output(self):
        """
        Returns the csv file as target to be loaded into database.

        :return: target output containing csv files.
        :rtype: object (:py:class:`luigi.target.Target`)
        """
        return luigi.LocalTarget(self.date.strftime("data/%Y_%m_%d" + "/" + Config.invoice_table + ".csv_outliers"))


class AssociationRulesLoading(luigi.contrib.postgres.CopyToTable):
    """
    This task will load generated association rules into database.
    """
    date = luigi.DateParameter()

    host = Config.host
    port = Config.port
    database = Config.database
    user = Config.user
    password = Config.password
    table = Config.association_rules_table
    column_separator = ","

    columns = [("antecedants", "TEXT"),
               ("consequents", "TEXT"),
               ("antecedent_support", "FLOAT"),
               ("consequent_support", "FLOAT"),
               ("support", "FLOAT"),
               ("confidence", "FLOAT"),
               ("lift", "FLOAT"),
               ("leverage", "FLOAT"),
               ("conviction", "FLOAT")]

    def requires(self):
        """
        This task depends on association rules generation.
        """
        return AssociationRulesGeneration(self.date)


class OutliersLoading(luigi.contrib.postgres.CopyToTable):
    """
    This task will load detected outliers into database.
    """
    date = luigi.DateParameter()

    host = Config.host
    port = Config.port
    database = Config.database
    user = Config.user
    password = Config.password
    table = Config.outliers_table
    column_separator = ","

    columns = [("invoice_no", "TEXT"),
               ("stock_code", "TEXT"),
               ("quantity", "INT"),
               ("invoice_date", "TEXT"),
               ("customer_id", "INT")]

    def requires(self):
        """
        This task depends on outliers detection task.
        """
        return OutliersDetection(self.date)


class CompleteDataDumpLoad(luigi.Task):
    """
    This is the final task in the data pipeline
    """
    date = luigi.DateParameter()

    def requires(self):
        """
        This task will execute only if association rules and outliers are loaded into database.
        :rtype: object (:py:class:`luigi.target.Target`)
        """
        return [AssociationRulesLoading(self.date),
                OutliersLoading(self.date)]
