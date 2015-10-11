use master;
begin
declare @sql nvarchar(max);
select @sql = coalesce(@sql,'') + 'kill ' + convert(varchar, spid) + ';'
from master..sysprocesses
where dbid in (db_id('BayMartGate'),db_id('DowneyDB'),db_id('OrangeDB'),db_id('PanoramaDB'),db_id('BayMartGlobalDB'),db_id('BayMartSourceDB')) and cmd = 'AWAITING COMMAND' and spid <> @@spid;
exec(@sql);
end;
go

if db_id('BayMartGate') 	is not null drop database BayMartGate;
if db_id('BayMartSourceDB') is not null drop database BayMartSourceDB;
if db_id('BayMartGlobalDB') is not null drop database BayMartGlobalDB;
if db_id('DowneyDB') 		is not null drop database DowneyDB;
if db_id('OrangeDB')  		is not null drop database OrangeDB;
if db_id('PanoramaDB') 		is not null drop database PanoramaDB;
create database BayMartSourceDB;
create database BayMartGlobalDB;
create database DowneyDB;
create database OrangeDB;
create database PanoramaDB;
go

use BayMartSourceDB;
create table Companies
	(	Id  				tinyint			 		not null primary key
	,	Name				nvarchar(128)			not null unique
	,	RowVersion			rowversion
	);
	
create table Stores
	(	Id					tinyint				 	not null primary key
	,	Name				nvarchar(128)			not null unique
	,	StoreNumber			nvarchar(16)			not null unique
	,	CompanyId			tinyint							 references Companies (Id)
	,	URL					nvarchar(512)			
	,	ContactName			nvarchar(64)
	,	ContactEMail		nvarchar(128)	
	,	ContactPhoneNumber	nvarchar(64)
	,	Country				nvarchar(2)
	,	City				nvarchar(128)
	,	Address				nvarchar(256)
	,	PostalCode			nvarchar(8)	
	,	RowVersion			rowversion
	);

create table Manufacturers
	(	Id  				smallint identity(1,1) 	not null primary key
	,	Name				nvarchar(128)			not null unique
	,	RowVersion			rowversion
	);

create table Publishers
	(	Id  				smallint identity(1,1) 	not null primary key
	,	Name				nvarchar(128)			not null unique
	);
	
create table Suppliers
	(	Id  				smallint identity(1,1) 	not null primary key
	,	Name				nvarchar(128)			not null unique
	);

create table Categories
	(	Id  				smallint identity(1,1) 	not null primary key
	,	Name				nvarchar(128)			not null unique
	,	ParentCategoryId	smallint
	,	RowVersion			rowversion
	);
	
alter table Categories add foreign key (ParentCategoryId) references Categories (Id);
	
create table Catalogs
	(	Id  				smallint identity(1,1) 	not null primary key
	,	Name				nvarchar(128)			not null unique
	,	RowVersion			rowversion
	);
	
create table Products
	(	Id  				bigint identity(1,1) 	not null primary key
	,	Name				nvarchar(256)			not null unique
	,	CatalogNumber		nvarchar(32)			not null
	,	CatalogId			smallint				not null references Catalogs (Id)
	,	CategoryId			smallint						 references Categories (Id)
	,	SupplierId			smallint						 references Suppliers (Id)
	,	PublisherId			smallint						 references Publishers (Id)
	,	ManufacturerId		smallint						 references Manufacturers (Id)
	,	Description			nvarchar(512)			
	,	Details				nvarchar(256)
	,	IconFileName		nvarchar(256)
	,	PublishDate			smalldatetime
	,	ExpireDate			smalldatetime
	,	RowVersion			rowversion
	,	unique (CatalogId,CatalogNumber)
	);	
	
create table Customers
	(	StoreId				tinyint				 	not null
	,	Id  				bigint identity(1,1) 	not null primary key
	,	FirstName			nvarchar(128)			not null
	,	LastName			nvarchar(128)			not null
	,	EMail				nvarchar(128)	
	,	PhoneNumber			nvarchar(64)
	,	Country				nvarchar(2)
	,	City				nvarchar(128)
	,	Address				nvarchar(256)
	,	PostalCode			nvarchar(8)	
	,	RowVersion			rowversion
	)
	
create table Items
	(	StoreId				tinyint				 	not null
	,	Id  				bigint identity(1,1) 	not null primary key
	,	ProductId			bigint					not null references Products (Id)
	,	Price				decimal(18,3)			not null
	,	PromotionPercent	decimal(18,3)			
	,	QuantityOrdered		smallint				not null
	,	QuantitySold		smallint				not null
	,	RowVersion			rowversion
	,	unique (StoreId,ProductId)
	);
	
create table Carts
	(	StoreId				tinyint				 	not null
	,	Id  				bigint identity(1,1) 	not null primary key
	,	CustomerId			bigint					not null references Customers (Id)
	,	ItemId				bigint					not null references Items (Id)
	,	QuantityOrdered		smallint				not null
	,	RowVersion			rowversion
	,	unique (CustomerId,ItemId)
	);
	
create table Orders
	(	StoreId				tinyint				 	not null
	,	Id  				bigint identity(1,1) 	not null primary key
	,	ItemId				bigint					not null references Items (Id)
	,	CustomerId			bigint					not null references Customers (Id)
	,	QuantityOrdered		smallint				not null
	,	OrderStatus			tinyint					not null
	,	OrderDate			smalldatetime			not null
	,	RowVersion			rowversion
	,	unique (ItemId,CustomerId)
	);
	
create table Reviews
	(	StoreId				tinyint				 	not null
	,	Id  				bigint identity(1,1) 	not null primary key
	,	ProductId			bigint					not null references Products (Id)
	,	CustomerId			bigint					not null references Customers (Id)
	,	Rating				tinyint					not null check (Rating between 0 and 5)
	,	Review				nvarchar(512)			
	,	unique (ProductId,CustomerId)
	);
	
create table Feedbacks
	(	StoreId				tinyint				 	not null
	,	Id  				bigint identity(1,1) 	not null primary key
	,	ReviewId			bigint					not null references Reviews (Id)
	,	IsHelpful			tinyint					not null check (IsHelpful in (0,1))
	,	Feedback			nvarchar(256)			
	);

create table ShoppingLog
	(	Id  				bigint identity(1,1) 	not null primary key
	,	StoreId				tinyint							 
	,	OrderId  			bigint 							 
	,	CartId  			bigint 							 
	,	ItemId				bigint							 
	,	ProductId			bigint							 
	,	CustomerId			bigint							 
	,	QuantityOrdered		smallint				
	,	OrderDate			smalldatetime			
	);

insert into Companies (Id,Name) values (1,'BayMart');	
	
insert into Stores (Id,Name,StoreNumber) values (1,'Downey','001');
insert into Stores (Id,Name,StoreNumber) values (2,'Orange','002');
insert into Stores (Id,Name,StoreNumber) values (3,'Panorama','003');
insert into Stores (Id,Name,StoreNumber) values (4,'Brea','004');
insert into Stores (Id,Name,StoreNumber) values (5,'Carson','005');
insert into Stores (Id,Name,StoreNumber) values (6,'Irvine','006');

insert into Categories (Name) values ('Advertising & Marketing');
insert into Categories (Name) values ('Agriculture');
insert into Categories (Name) values ('Arcade Equipment');
insert into Categories (Name) values ('Athletics');
insert into Categories (Name) values ('Audio');
insert into Categories (Name) values ('Baby & Toddler Furniture');
insert into Categories (Name) values ('Baby Bathing');
insert into Categories (Name) values ('Baby Gift Sets');
insert into Categories (Name) values ('Baby Health');
insert into Categories (Name) values ('Baby Safety');
insert into Categories (Name) values ('Baby Transport');
insert into Categories (Name) values ('Baby Transport Accessories');
insert into Categories (Name) values ('Backpacks');
insert into Categories (Name) values ('Bathroom Accessories');
insert into Categories (Name) values ('Beds & Accessories');
insert into Categories (Name) values ('Benches');
insert into Categories (Name) values ('Beverages');
insert into Categories (Name) values ('Book Accessories');
insert into Categories (Name) values ('Books');
insert into Categories (Name) values ('Briefcases');
insert into Categories (Name) values ('Business & Home Security');
insert into Categories (Name) values ('Cabinets & Storage');
insert into Categories (Name) values ('Camera & Optic Accessories');
insert into Categories (Name) values ('Cameras');
insert into Categories (Name) values ('Carpentry & Woodworking Project Plans');
insert into Categories (Name) values ('Chair Accessories');
insert into Categories (Name) values ('Chairs');
insert into Categories (Name) values ('Circuit Boards & Components');
insert into Categories (Name) values ('Clothing');
insert into Categories (Name) values ('Clothing Accessories');
insert into Categories (Name) values ('Communications');
insert into Categories (Name) values ('Components');
insert into Categories (Name) values ('Computer Software');
insert into Categories (Name) values ('Computers');
insert into Categories (Name) values ('Construction');
insert into Categories (Name) values ('Cosmetic & Toiletry Bags');
insert into Categories (Name) values ('Costumes & Accessories');
insert into Categories (Name) values ('Decor');
insert into Categories (Name) values ('Dentistry');
insert into Categories (Name) values ('Diaper Bags');
insert into Categories (Name) values ('Diapering');
insert into Categories (Name) values ('Digital Goods & Currency');
insert into Categories (Name) values ('DVDs & Videos');
insert into Categories (Name) values ('Electronics Accessories');
insert into Categories (Name) values ('Emergency Preparedness');
insert into Categories (Name) values ('Entertainment Centers & TV Stands');
insert into Categories (Name) values ('Exercise & Fitness');
insert into Categories (Name) values ('Fanny Packs');
insert into Categories (Name) values ('Fencing & Barriers');
insert into Categories (Name) values ('Filing & Organization');
insert into Categories (Name) values ('Film & Television');
insert into Categories (Name) values ('Finance & Insurance');
insert into Categories (Name) values ('Fireplace & Wood Stove Accessories');
insert into Categories (Name) values ('Fireplaces');
insert into Categories (Name) values ('Flood, Fire & Gas Safety');
insert into Categories (Name) values ('Food Items');
insert into Categories (Name) values ('Food Service');
insert into Categories (Name) values ('Furniture Sets');
insert into Categories (Name) values ('Games');
insert into Categories (Name) values ('GPS Tracking Devices');
insert into Categories (Name) values ('Hairdressing & Cosmetology');
insert into Categories (Name) values ('Handbag & Wallet Accessories');
insert into Categories (Name) values ('Handbags, Wallets & Cases');
insert into Categories (Name) values ('Hardware Accessories');
insert into Categories (Name) values ('Health Care');
insert into Categories (Name) values ('Heating, Ventilation & Air Conditioning');
insert into Categories (Name) values ('Heavy Machinery');
insert into Categories (Name) values ('Hobbies & Creative Arts');
insert into Categories (Name) values ('Hotel & Hospitality');
insert into Categories (Name) values ('Household Appliance Accessories');
insert into Categories (Name) values ('Household Appliances');
insert into Categories (Name) values ('Household Supplies');
insert into Categories (Name) values ('Indoor Games');
insert into Categories (Name) values ('Industrial Storage');
insert into Categories (Name) values ('Industrial Storage Accessories');
insert into Categories (Name) values ('Jewelry');
insert into Categories (Name) values ('Jewelry Cleaning & Care');
insert into Categories (Name) values ('Kitchen & Dining');
insert into Categories (Name) values ('Lap Desks');
insert into Categories (Name) values ('Law Enforcement');
insert into Categories (Name) values ('Lawn & Garden');
insert into Categories (Name) values ('Lighting');
insert into Categories (Name) values ('Lighting Accessories');
insert into Categories (Name) values ('Live Animals');
insert into Categories (Name) values ('Locks & Keys');
insert into Categories (Name) values ('Magazines & Newspapers');
insert into Categories (Name) values ('Manufacturing');
insert into Categories (Name) values ('Marine Electronics');
insert into Categories (Name) values ('Medical');
insert into Categories (Name) values ('Music & Sound Recordings');
insert into Categories (Name) values ('Networking');
insert into Categories (Name) values ('Nursing & Feeding');
insert into Categories (Name) values ('Office Carts');
insert into Categories (Name) values ('Office Equipment');
insert into Categories (Name) values ('Office Furniture');
insert into Categories (Name) values ('Office Furniture Accessories');
insert into Categories (Name) values ('Office Instruments');
insert into Categories (Name) values ('Optics');
insert into Categories (Name) values ('Outdoor Furniture');
insert into Categories (Name) values ('Outdoor Furniture Accessories');
insert into Categories (Name) values ('Outdoor Play Equipment');
insert into Categories (Name) values ('Outdoor Recreation');
insert into Categories (Name) values ('Party & Celebration');
insert into Categories (Name) values ('Personal Care');
insert into Categories (Name) values ('Pet Supplies');
insert into Categories (Name) values ('Photography');
insert into Categories (Name) values ('Piercing & Tattooing');
insert into Categories (Name) values ('Plants');
insert into Categories (Name) values ('Plumbing');
insert into Categories (Name) values ('Pool & Spa');
insert into Categories (Name) values ('Power & Electrical Supplies');
insert into Categories (Name) values ('Print, Copy, Scan & Fax');
insert into Categories (Name) values ('Religious Items');
insert into Categories (Name) values ('Retail');
insert into Categories (Name) values ('Room Divider Accessories');
insert into Categories (Name) values ('Room Dividers');
insert into Categories (Name) values ('Science & Laboratory');
insert into Categories (Name) values ('Shelving');
insert into Categories (Name) values ('Shelving Accessories');
insert into Categories (Name) values ('Shoe Accessories');
insert into Categories (Name) values ('Shoes');
insert into Categories (Name) values ('Smoking Accessories');
insert into Categories (Name) values ('Sofa Accessories');
insert into Categories (Name) values ('Sofas');
insert into Categories (Name) values ('Suitcases');
insert into Categories (Name) values ('Table Accessories');
insert into Categories (Name) values ('Tables');
insert into Categories (Name) values ('Tobacco Products');
insert into Categories (Name) values ('Tool Accessories');
insert into Categories (Name) values ('Tools');
insert into Categories (Name) values ('Toys');
insert into Categories (Name) values ('Vehicle Parts & Accessories');
insert into Categories (Name) values ('Vehicles');
insert into Categories (Name) values ('Video');
insert into Categories (Name) values ('Video Game Consoles');
insert into Categories (Name) values ('Video Game Software');
insert into Categories (Name) values ('Weapons');

insert into Catalogs (Name) values ('Novel List');

insert into Manufacturers (Name) values ('AA Milne');
insert into Manufacturers (Name) values ('Aldous Huxley');
insert into Manufacturers (Name) values ('Alexandre Dumas');
insert into Manufacturers (Name) values ('Alice Sebold');
insert into Manufacturers (Name) values ('Alice Walker');
insert into Manufacturers (Name) values ('Antoine De Saint Exupery');
insert into Manufacturers (Name) values ('Arthur Golden');
insert into Manufacturers (Name) values ('Arthur Ransome');
insert into Manufacturers (Name) values ('AS Byatt');
insert into Manufacturers (Name) values ('Audrey Niffenegger');
insert into Manufacturers (Name) values ('Bill Bryson');
insert into Manufacturers (Name) values ('Bram Stoker');
insert into Manufacturers (Name) values ('Carlos Ruiz Zafon');
insert into Manufacturers (Name) values ('Charles Dickens');
insert into Manufacturers (Name) values ('Charlotte Bronte');
insert into Manufacturers (Name) values ('CS Lewis');
insert into Manufacturers (Name) values ('Dan Brown');
insert into Manufacturers (Name) values ('Daphne Du Maurier');
insert into Manufacturers (Name) values ('David Mitchell');
insert into Manufacturers (Name) values ('Donna Tartt');
insert into Manufacturers (Name) values ('Douglas Adams');
insert into Manufacturers (Name) values ('EB White');
insert into Manufacturers (Name) values ('Emile Zola');
insert into Manufacturers (Name) values ('Emily Brontë');
insert into Manufacturers (Name) values ('Enid Blyton');
insert into Manufacturers (Name) values ('Evelyn Waugh');
insert into Manufacturers (Name) values ('F Scott Fitzgerald');
insert into Manufacturers (Name) values ('Frances Hodgson');
insert into Manufacturers (Name) values ('Frank Herbert');
insert into Manufacturers (Name) values ('Fyodor Dostoyevsky');
insert into Manufacturers (Name) values ('Gabriel Garcia Marquez');
insert into Manufacturers (Name) values ('George Eliot');
insert into Manufacturers (Name) values ('George Orwell');
insert into Manufacturers (Name) values ('Gustave Flaubert');
insert into Manufacturers (Name) values ('Harper Lee');
insert into Manufacturers (Name) values ('Helen Fielding');
insert into Manufacturers (Name) values ('Herman Melville');
insert into Manufacturers (Name) values ('Iain Banks');
insert into Manufacturers (Name) values ('Ian McEwan');
insert into Manufacturers (Name) values ('Jack Kerouac');
insert into Manufacturers (Name) values ('James Joyce');
insert into Manufacturers (Name) values ('Jane Austen');
insert into Manufacturers (Name) values ('JD Salinger');
insert into Manufacturers (Name) values ('JK Rowling (all)');
insert into Manufacturers (Name) values ('John Irving');
insert into Manufacturers (Name) values ('John Kennedy Toole');
insert into Manufacturers (Name) values ('John Steinbeck');
insert into Manufacturers (Name) values ('Joseph Conrad');
insert into Manufacturers (Name) values ('Joseph Heller');
insert into Manufacturers (Name) values ('JRR Tolkien');
insert into Manufacturers (Name) values ('Kazuo Ishiguro');
insert into Manufacturers (Name) values ('Kenneth Grahame');
insert into Manufacturers (Name) values ('Khaled Hosseini');
insert into Manufacturers (Name) values ('Leo Tolstoy');
insert into Manufacturers (Name) values ('Lewis Carroll');
insert into Manufacturers (Name) values ('LM Montgomery');
insert into Manufacturers (Name) values ('Louis De Berniere');
insert into Manufacturers (Name) values ('Louisa May Alcott');
insert into Manufacturers (Name) values ('Margaret Atwood');
insert into Manufacturers (Name) values ('Margaret Mitchell');
insert into Manufacturers (Name) values ('Mark Haddon');
insert into Manufacturers (Name) values ('Mitch Albom');
insert into Manufacturers (Name) values ('Moses');
insert into Manufacturers (Name) values ('Nevil Shute');
insert into Manufacturers (Name) values ('Philip Pullman');
insert into Manufacturers (Name) values ('Richard Adams');
insert into Manufacturers (Name) values ('Roald Dahl');
insert into Manufacturers (Name) values ('Rohinton Mistry');
insert into Manufacturers (Name) values ('Salman Rushdie');
insert into Manufacturers (Name) values ('Sebastian Faulks');
insert into Manufacturers (Name) values ('Sir Arthur Conan Doyle');
insert into Manufacturers (Name) values ('Stella Gibbons');
insert into Manufacturers (Name) values ('Sylvia Plath');
insert into Manufacturers (Name) values ('Thomas Hardy');
insert into Manufacturers (Name) values ('Victor Hugo');
insert into Manufacturers (Name) values ('Vikram Seth');
insert into Manufacturers (Name) values ('Vladimir Nabokov');
insert into Manufacturers (Name) values ('Wilkie Collins');
insert into Manufacturers (Name) values ('William Golding');
insert into Manufacturers (Name) values ('William Makepeace Thackeray');
insert into Manufacturers (Name) values ('William Shakespeare');
insert into Manufacturers (Name) values ('Yann Martel');

insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Pride and Prejudice','0001',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Jane Austen'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Lord of the Rings','0002',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'JRR Tolkien'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Jane Eyre','0003',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Charlotte Bronte'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Harry Potter Series','0004',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'JK Rowling (all)'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('To Kill a Mockingbird','0005',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Harper Lee'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Bible','0006',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Moses'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Wuthering Heights','0007',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Emily Brontë'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Nineteen Eighty Four','0008',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'George Orwell'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('His Dark Materials','0009',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Philip Pullman'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Great Expectations','0010',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Charles Dickens'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Little Women','0011',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Louisa May Alcott'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Tess of the DUrbervilles','0012',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Thomas Hardy'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Catch 22','0013',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Joseph Heller'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Romeo and Juliet','0014',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'William Shakespeare'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Rebecca','0015',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Daphne Du Maurier'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Hobbit','0016',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'JRR Tolkien'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Birdsong','0017',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Sebastian Faulks'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Catcher in the Rye','0018',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'JD Salinger'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Time Travelers Wife','0019',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Audrey Niffenegger'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Middlemarch','0020',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'George Eliot'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Gone With The Wind','0021',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Margaret Mitchell'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Great Gatsby','0022',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'F Scott Fitzgerald'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Bleak House','0023',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Charles Dickens'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('War and Peace','0024',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Leo Tolstoy'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Hitchhiker’s Guide to the Galaxy','0025',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Douglas Adams'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Brideshead Revisited','0026',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Evelyn Waugh'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Crime and Punishment','0027',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Fyodor Dostoyevsky'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Grapes of Wrath','0028',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'John Steinbeck'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Alice in Wonderland','0029',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Lewis Carroll'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Wind in the Willows','0030',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Kenneth Grahame'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Anna Karenina','0031',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Leo Tolstoy'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('David Copperfield','0032',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Charles Dickens'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Chronicles of Narnia','0033',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'CS Lewis'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Emma','0034',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Jane Austen'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Persuasion','0035',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Jane Austen'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Lion, The Witch and The Wardrobe','0036',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'CS Lewis'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Kite Runner','0037',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Khaled Hosseini'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Captain Corelli’s Mandolin','0038',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Louis De Berniere'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Memoirs of a Geisha','0039',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Arthur Golden'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Winnie the Pooh','0040',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'AA Milne'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Animal Farm','0041',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'George Orwell'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Da Vinci Code','0042',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Dan Brown'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('One Hundred Years of Solitude','0043',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Gabriel Garcia Marquez'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('A Prayer for Owen Meany','0044',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'John Irving'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Woman in White','0045',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Wilkie Collins'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Anne of Green Gables','0046',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'LM Montgomery'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Far from the Madding Crowd','0047',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Thomas Hardy'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Handmaids Tale','0048',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Margaret Atwood'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Lord of the Flies','0049',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'William Golding'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Atonement','0050',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Ian McEwan'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Life of Pi','0051',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Yann Martel'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Dune','0052',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Frank Herbert'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Cold Comfort Farm','0053',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Stella Gibbons'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Sense and Sensibility','0054',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Jane Austen'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('A Suitable Boy','0055',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Vikram Seth'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Shadow of the Wind','0056',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Carlos Ruiz Zafon'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('A Tale Of Two Cities','0057',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Charles Dickens'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Brave New World','0058',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Aldous Huxley'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Curious Incident of the Dog in the Night-time','0059',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Mark Haddon'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Love in the Time of Cholera','0060',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Gabriel Garcia Marquez'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Of Mice and Men','0061',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'John Steinbeck'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Lolita','0062',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Vladimir Nabokov'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Secret History','0063',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Donna Tartt'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Lovely Bones','0064',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Alice Sebold'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Count of Monte Cristo','0065',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Alexandre Dumas'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('On the Road','0066',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Jack Kerouac'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Jude the Obscure','0067',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Thomas Hardy'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Bridget Jones’s Diary','0068',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Helen Fielding'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Midnight’s Children','0069',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Salman Rushdie'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Moby Dick','0070',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Herman Melville'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Oliver Twist','0071',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Charles Dickens'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Dracula','0072',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Bram Stoker'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Secret Garden','0073',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Frances Hodgson'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Notes from a Small Island','0074',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Bill Bryson'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Ulysses','0075',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'James Joyce'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Bell Jar','0076',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Sylvia Plath'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Swallows and Amazons','0077',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Arthur Ransome'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Germinal','0078',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Emile Zola'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Vanity Fair','0079',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'William Makepeace Thackeray'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Possession','0080',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'AS Byatt'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('A Christmas Carol','0081',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Charles Dickens'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Cloud Atlas','0082',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'David Mitchell'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Colour Purple','0083',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Alice Walker'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Remains of the Day','0084',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Kazuo Ishiguro'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Madame Bovary','0085',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Gustave Flaubert'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('A Fine Balance','0086',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Rohinton Mistry'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Charlottes Web','0087',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'EB White'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Five People You Meet In Heaven','0088',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Mitch Albom'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Adventures of Sherlock Holmes','0089',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Sir Arthur Conan Doyle'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Faraway Tree Collection','0090',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Enid Blyton'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Heart of Darkness','0091',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Joseph Conrad'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Little Prince','0092',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Antoine De Saint Exupery'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Wasp Factory','0093',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Iain Banks'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Watership Down','0094',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Richard Adams'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('A Confederacy of Dunces','0095',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'John Kennedy Toole'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('A Town Like Alice','0096',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Nevil Shute'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('The Three Musketeers','0097',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Alexandre Dumas'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Hamlet','0098',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'William Shakespeare'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Charlie & the Chocolate Factory','0099',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Roald Dahl'));
insert into Products (Name,CatalogNumber,CatalogId,CategoryId,ManufacturerId) values ('Les Miserables','0100',1,(select top 1 Id from Categories where Name = 'Books'),(select top 1 Id from Manufacturers where Name = 'Victor Hugo'));

insert into Customers (StoreId,FirstName,LastName) values (1,'Bill','Gates');
insert into Customers (StoreId,FirstName,LastName) values (2,'Warren','Buffett');
insert into Customers (StoreId,FirstName,LastName) values (3,'Charles','Koch');
insert into Customers (StoreId,FirstName,LastName) values (1,'David','Koch');
insert into Customers (StoreId,FirstName,LastName) values (2,'Christy','Walton');
insert into Customers (StoreId,FirstName,LastName) values (3,'Liliane','Bettencourt');
insert into Customers (StoreId,FirstName,LastName) values (1,'Alice','Walton');
insert into Customers (StoreId,FirstName,LastName) values (2,'Karl','Albrecht');
insert into Customers (StoreId,FirstName,LastName) values (3,'Bernard','Arnault');
insert into Customers (StoreId,FirstName,LastName) values (1,'Michael','Bloomberg');
insert into Customers (StoreId,FirstName,LastName) values (2,'Jeff','Bezos');
insert into Customers (StoreId,FirstName,LastName) values (3,'Mark','Zuckerberg');
insert into Customers (StoreId,FirstName,LastName) values (1,'Sheldon','Adelson');
insert into Customers (StoreId,FirstName,LastName) values (2,'Larry','Page');
insert into Customers (StoreId,FirstName,LastName) values (3,'Sergey','Brin');
insert into Customers (StoreId,FirstName,LastName) values (1,'Georg','Schaeffler');
insert into Customers (StoreId,FirstName,LastName) values (2,'Forrest','Mars');
insert into Customers (StoreId,FirstName,LastName) values (3,'Jacqueline','Mars');
insert into Customers (StoreId,FirstName,LastName) values (1,'John','Mars');
insert into Customers (StoreId,FirstName,LastName) values (2,'David','Thomson');
insert into Customers (StoreId,FirstName,LastName) values (3,'Lee','Shau Kee');
insert into Customers (StoreId,FirstName,LastName) values (1,'Stefan','Persson');
insert into Customers (StoreId,FirstName,LastName) values (2,'George','Soros');
insert into Customers (StoreId,FirstName,LastName) values (3,'Wang','Jianlin');
insert into Customers (StoreId,FirstName,LastName) values (1,'Carl','Icahn');
insert into Customers (StoreId,FirstName,LastName) values (2,'Jack','Ma');
insert into Customers (StoreId,FirstName,LastName) values (3,'Raymond','Kwok');
insert into Customers (StoreId,FirstName,LastName) values (1,'Phil','Knight');
insert into Customers (StoreId,FirstName,LastName) values (2,'Steve','Ballmer');
insert into Customers (StoreId,FirstName,LastName) values (3,'Beate','Heister');
insert into Customers (StoreId,FirstName,LastName) values (1,'Li','Hejun');
insert into Customers (StoreId,FirstName,LastName) values (2,'Mukesh','Ambani');
insert into Customers (StoreId,FirstName,LastName) values (3,'mancio','Ortega');
insert into Customers (StoreId,FirstName,LastName) values (1,'Len','Blavatnik');
insert into Customers (StoreId,FirstName,LastName) values (2,'Tadashi','Yanai');
insert into Customers (StoreId,FirstName,LastName) values (3,'Charles','Ergen');
insert into Customers (StoreId,FirstName,LastName) values (1,'Dilip','Shanghvi');
insert into Customers (StoreId,FirstName,LastName) values (2,'Laurene','Powell');
insert into Customers (StoreId,FirstName,LastName) values (3,'Dieter','Schwarz');
insert into Customers (StoreId,FirstName,LastName) values (1,'Michael','Dell');
insert into Customers (StoreId,FirstName,LastName) values (2,'Azim','Premji');
insert into Customers (StoreId,FirstName,LastName) values (3,'Theo','Albrecht');
insert into Customers (StoreId,FirstName,LastName) values (1,'arry','Ellison');
insert into Customers (StoreId,FirstName,LastName) values (2,'Michael','Otto');
insert into Customers (StoreId,FirstName,LastName) values (3,'Paul','Allen');
insert into Customers (StoreId,FirstName,LastName) values (1,'Joseph','Safra');
insert into Customers (StoreId,FirstName,LastName) values (2,'Susanne','Klatten');
insert into Customers (StoreId,FirstName,LastName) values (3,'Pallonji','Mistry');
insert into Customers (StoreId,FirstName,LastName) values (1,'Ma','Huateng');
insert into Customers (StoreId,FirstName,LastName) values (2,'Patrick','Drahi');
insert into Customers (StoreId,FirstName,LastName) values (3,'Thomas','Kwok');
insert into Customers (StoreId,FirstName,LastName) values (1,'Stefan','Quandt');
insert into Customers (StoreId,FirstName,LastName) values (2,'Ray','Dalio');
insert into Customers (StoreId,FirstName,LastName) values (3,'Vladimir','Potanin');
insert into Customers (StoreId,FirstName,LastName) values (1,'Robin','Li');
insert into Customers (StoreId,FirstName,LastName) values (2,'Serge','Dassault');
insert into Customers (StoreId,FirstName,LastName) values (3,'Donald','Bren');
insert into Customers (StoreId,FirstName,LastName) values (4,'Mikhail','Fridman');
insert into Customers (StoreId,FirstName,LastName) values (5,'Hinduja','Brothers');
insert into Customers (StoreId,FirstName,LastName) values (6,'Ronald','Perelman');
insert into Customers (StoreId,FirstName,LastName) values (4,'Alisher','Usmanov');
insert into Customers (StoreId,FirstName,LastName) values (5,'Henry','Sy');
insert into Customers (StoreId,FirstName,LastName) values (6,'Viktor','Vekselberg');
insert into Customers (StoreId,FirstName,LastName) values (4,'Masayoshi','Son');
insert into Customers (StoreId,FirstName,LastName) values (5,'James','Simons');
insert into Customers (StoreId,FirstName,LastName) values (6,'Simon','Reuben');
insert into Customers (StoreId,FirstName,LastName) values (4,'Johanna','Quandt');
insert into Customers (StoreId,FirstName,LastName) values (5,'Rupert','Murdoch');
insert into Customers (StoreId,FirstName,LastName) values (6,'David','Reuben');
insert into Customers (StoreId,FirstName,LastName) values (4,'Dhanin','Chearavanont');
insert into Customers (StoreId,FirstName,LastName) values (5,'Iris','Fontbona');
insert into Customers (StoreId,FirstName,LastName) values (6,'Lakshmi','Mittal');
insert into Customers (StoreId,FirstName,LastName) values (4,'Lui','Che Woo');
insert into Customers (StoreId,FirstName,LastName) values (5,'Abigail','Johnson');
insert into Customers (StoreId,FirstName,LastName) values (6,'Luis','Carlos Sarmiento');
insert into Customers (StoreId,FirstName,LastName) values (4,'Charoen','Sirivadhanabhakdi');
insert into Customers (StoreId,FirstName,LastName) values (5,'Lei','Jun');
insert into Customers (StoreId,FirstName,LastName) values (6,'Alexey','Mordashov');
insert into Customers (StoreId,FirstName,LastName) values (4,'im','Walton');
insert into Customers (StoreId,FirstName,LastName) values (5,'Hans','Rausing');
insert into Customers (StoreId,FirstName,LastName) values (6,'Jack','Taylor');
insert into Customers (StoreId,FirstName,LastName) values (4,'Charles','Butt');
insert into Customers (StoreId,FirstName,LastName) values (5,'Gina','Rinehart');
insert into Customers (StoreId,FirstName,LastName) values (6,'Harold','Hamm');
insert into Customers (StoreId,FirstName,LastName) values (4,'Vagit','Alekperov');
insert into Customers (StoreId,FirstName,LastName) values (5,'Stefano','Pessina');
insert into Customers (StoreId,FirstName,LastName) values (6,'Richard','Kinder');

insert into Items (StoreId,ProductId,Price,QuantityOrdered,QuantitySold)
select case when cast(CatalogNumber as tinyint) % 3 = 0 then 3 else cast(CatalogNumber as tinyint) % 3 end,Id,100,0,0
from Products
where cast(CatalogNumber as tinyint) <= 90;

insert into Items (StoreId,ProductId,Price,QuantityOrdered,QuantitySold)
select case when cast(CatalogNumber as tinyint) % 3 = 0 then 3 else cast(CatalogNumber as tinyint) % 3 end + 3,Id,100,0,0
from Products
where cast(CatalogNumber as tinyint) between 91 and 99;

insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (1,1,1,1,1,1,100,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (2,2,2,2,2,2,200,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (3,3,3,3,3,3,300,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (4,4,4,4,4,4,400,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (5,5,5,5,5,5,500,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (6,6,6,6,6,6,600,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (7,7,7,7,7,7,700,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (8,8,8,8,8,8,800,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (9,9,9,9,9,9,900,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (10,10,10,10,10,10,1000,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (11,11,11,11,11,11,1100,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (12,12,12,12,12,12,1200,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (13,13,13,13,13,13,1300,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (14,14,14,14,14,14,1400,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (15,15,15,15,15,15,1500,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (16,16,16,16,16,16,1600,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (17,17,17,17,17,17,1700,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (18,18,18,18,18,18,1800,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (19,19,19,19,19,19,1900,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (20,20,20,20,20,20,2000,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (21,21,21,21,21,21,2100,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (22,22,22,22,22,22,2200,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (23,23,23,23,23,23,2300,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (24,24,24,24,24,24,2400,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (25,25,25,25,25,25,2500,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (26,26,26,26,26,26,2600,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (27,27,27,27,27,27,2700,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (28,28,28,28,28,28,2800,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (29,29,29,29,29,29,2900,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (30,30,30,30,30,30,3000,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (31,31,31,31,31,31,3100,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (32,32,32,32,32,32,3200,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (33,33,33,33,33,33,3300,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (34,34,34,34,34,34,3400,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (35,35,35,35,35,35,3500,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (36,36,36,36,36,36,3600,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (37,37,37,37,37,37,3700,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (38,38,38,38,38,38,3800,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (39,39,39,39,39,39,3900,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (40,40,40,40,40,40,4000,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (41,41,41,41,41,41,4100,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (42,42,42,42,42,42,4200,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (43,43,43,43,43,43,4300,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (44,44,44,44,44,44,4400,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (45,45,45,45,45,45,4500,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (46,46,46,46,46,46,4600,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (47,47,47,47,47,47,4700,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (48,48,48,48,48,48,4800,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (49,49,49,49,49,49,4900,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (50,50,50,50,50,50,5000,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (51,51,51,51,51,51,5100,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (52,52,52,52,52,52,5200,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (53,53,53,53,53,53,5300,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (54,54,54,54,54,54,5400,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (55,55,55,55,55,55,5500,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (56,56,56,56,56,56,5600,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (57,57,57,57,57,57,5700,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (58,58,58,58,58,58,5800,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (59,59,59,59,59,59,5900,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (60,60,60,60,60,60,6000,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (61,61,61,61,61,61,6100,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (62,62,62,62,62,62,6200,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (63,63,63,63,63,63,6300,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (64,64,64,64,64,64,6400,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (65,65,65,65,65,65,6500,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (66,66,66,66,66,66,6600,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (67,67,67,67,67,67,6700,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (68,68,68,68,68,68,6800,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (69,69,69,69,69,69,6900,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (70,70,70,70,70,70,7000,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (71,71,71,71,71,71,7100,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (72,72,72,72,72,72,7200,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (73,73,73,73,73,73,7300,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (74,74,74,74,74,74,7400,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (75,75,75,75,75,75,7500,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (76,76,76,76,76,76,7600,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (77,77,77,77,77,77,7700,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (78,78,78,78,78,78,7800,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (79,79,79,79,79,79,7900,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (80,80,80,80,80,80,8000,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (81,81,81,81,81,81,8100,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (82,82,82,82,82,82,8200,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (83,83,83,83,83,83,8300,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (84,84,84,84,84,84,8400,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (85,85,85,85,85,85,8500,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (86,86,86,86,86,86,8600,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (87,87,87,87,87,87,8700,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (88,88,88,88,88,88,8800,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (89,89,89,89,89,89,8900,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (90,90,90,90,90,90,9000,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (91,91,91,91,91,91,9100,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (92,92,92,92,92,92,9200,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (93,93,93,93,93,93,9300,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (94,94,94,94,94,94,9400,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (95,95,95,95,95,95,9500,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (96,96,96,96,96,96,9600,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (97,97,97,97,97,97,9700,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (98,98,98,98,98,98,9800,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (99,99,99,99,99,99,9900,cast(getdate() as smalldatetime));
insert into ShoppingLog (StoreId,OrderId,CartId,ItemId,ProductId,CustomerId,QuantityOrdered,OrderDate) values (100,100,100,100,100,100,10000,cast(getdate() as smalldatetime));

use PdbLogic;
exec Pdbinstall 'BayMartGate',@ColumnName='StoreId',@ProductTypeId=2;
go
use BayMartGate;
exec PdbcreatePartition 'BayMartGate','BayMartGlobalDB',@DatabaseTypeId=3;
exec PdbcreatePartition 'BayMartGate','DowneyDB',1;
exec PdbcreatePartition 'BayMartGate','OrangeDB',2;
exec PdbcreatePartition 'BayMartGate','PanoramaDB',3;

exec PdbsyncSourceTable 'BayMartGate','dbo','Customers'		,'BayMartSourceDB',@Columns='StoreId,Id,FirstName,LastName,RowVersion'					,@SyncInterval=1;
exec PdbsyncSourceTable 'BayMartGate','dbo','Items'			,'BayMartSourceDB',@IsUpdate=0,@IsDelete=0,@SyncInterval=1;
exec PdbsyncSourceTable 'BayMartGate','dbo','Carts'			,'BayMartSourceDB',@SyncInterval=1;
exec PdbsyncSourceTable 'BayMartGate','dbo','Orders'		,'BayMartSourceDB',@SyncInterval=1;
exec PdbsyncSourceTable 'BayMartGate','dbo','Reviews'		,'BayMartSourceDB',@IsUpdate=0,@SyncInterval=1;
exec PdbsyncSourceTable 'BayMartGate','dbo','Feedbacks'		,'BayMartSourceDB',@IsUpdate=0,@SyncInterval=1;

use BayMartSourceDB;
insert into Customers (StoreId,FirstName,LastName) values (1,'Francois','Pinault');		-- Checking Insert Works
insert into Customers (StoreId,FirstName,LastName) values (2,'Shiv','Nadar');               
insert into Customers (StoreId,FirstName,LastName) values (3,'Aliko','Dangote');            

delete from Items where StoreId = 2;													-- Checking Delete disabled
update Items set Price = 200 where StoreId = 1;											-- Checking Update disabled

use BayMartGate;
update PdbSourceTables set LastSyncTime = null; -- AMIT: Temporary for quick sync
exec Pdbsync 'BayMartGate';

select * from PdbCustomers where FirstName = 'Francois' and LastName='Pinault'; 		-- Have Row = Insert Worked
select * from PdbItems where StoreId = 2;												-- Have Row = Delete Disabled
select * from PdbItems where StoreId = 1;												-- All Price 100 = Update Disabled

-- Changing Sync Interval and Adding Columns
exec PdbsyncSourceTable 'BayMartGate','dbo','Customers'		,'BayMartSourceDB',@Columns='StoreId,Id,FirstName,LastName,EMail,RowVersion'			,@SyncInterval=10; -- Adding EMail
exec PdbsyncSourceTable 'BayMartGate','dbo','Items'			,'BayMartSourceDB',@IsUpdate=1,@IsDelete=1,@SyncInterval=1;

use BayMartSourceDB;
update Customers set EMail = 'support@partitiondb.com';									-- Checking New Email
delete from Items where StoreId = 3;													-- Checking Delete Works
update Items set Price = 300 where StoreId = 1;											-- Checking Update Works

use BayMartGate;
update PdbSourceTables set LastSyncTime = null; -- AMIT: Temporary for quick sync
exec Pdbsync 'BayMartGate';
select * from PdbCustomers;																-- Email updated
select * from PdbItems where StoreId = 3;												-- No Have Row = Delete Works
select * from PdbItems where StoreId = 1;												-- All Price 300 = Update Works