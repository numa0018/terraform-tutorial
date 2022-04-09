# 基本構文

## 変数 
- 変数を定義する。
- 実行時は上書き可能である。
  - コマンド実行時に上書き。
    - `$ terraform plan -var 'example_instance_type=t3.nano'`
  - 環境変数で上書き。
    - 環境変数の場合、`「TF_VAR_<名前>」`という名前にすると、Terraformが自動的に上書きする
    - `$ TF_VAR_example_instance_type=t3.nano terraform plan`
```variable.tf
valiable "example_instance_type" {
  default = "t3.micro"
}
resource "aws_instance" "example" {
  ami = "ami-xxxxxxxxx"
  instance_type = var.example_instance_type
 }
```
## ローカル変数 
- ローカル変数を定義する。
- variableとは異なり、コマンド実行時に上書きできない。
```locals.tf
locals {
  example_instance_type = "t3.micro" 
}

resource "aws_instance" "example" {
  ami = "ami-xxxxxxxxxxxx"
  instance_type = local.example_instance_type
}
```
## 出力値
- 出力値を定義する
- ex.) 実行結果の最後に、作成されたインスタンスのIDが出力される
```output.tf
resource "aws_instance" "example" {
  ami = "ami-xxxxxxxxxxxx"
  instance_type = "t3.micro" 
}

output "example_instance_id" {
  value = aws_instance.exaple.id
}

結果
$ terraform apply
Outputs:

exaple_instance_di = i-xxxxxxxxxxxxxx
```  

## データソース
- 外部データを参照する
- ex.) 最新のAmazonLinux2のAMIを取得。filter:検索条件
```data.tf
data "aws_ami" "amlx2" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-2.0.????????-x86_64-gp2"]
  }
  filter {
    name = "state"
    values = ["avairable"]
  }
}

resource "aws_instance" "example" {
  ami = data.aws_ami.amlx2.image_id
  instacne_type = "t3.micro"
}
```

## プロバイダ
- 各クラウドサービスのAPIの違いを吸収する役割
- プロバイダはTerraform本体とは切り離されているため、initコマンドでプロバイダのバイナリファイルをダウンロードする必要がある。
```provider.tf
provider "aws" {
  region = "ap-northeast-1"
}
```

## 参照
  - **1 [TYEP.NAME.ATTRIBUTE]他のリソースの値を参照できる
  - apply時に出力されるpublic_dnsにアクセスできるようになる
    - SecurityGroupが付いているから
```reference.tf
resource "aws_security_group" "security_group_for_ec2" {
  name = "security_group_for_ec2"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0 
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "aws_instance" "test_instance" {
  ami = "ami-0521a4a0a1329ff86"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.security_group_for_ec2.id] **1
  tags = {
    Name = "hoge_instance"
  }
  user_data = <<EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd.service
EOF
}

output "example_public_dns" {
  value = aws_instance.test_instance.public_dns
}
```

## 組み込み関数
- 文字列操作やコレクション操作は、組み込み関数とて用意されている
- ex.) 外部ファイルを読み込むfile関数を使用。
  - main.tfと同じ階層に`user_data.sh`を作成。
  - #!/bin/bash \n yum install -y httpd \n sytemctl start httpd.service
```buildinfunctions.tf
resource "aws_instance" "example" {
  ami = "ami-xxxxxxxxxxx"
  instance_type = "t3.micro"
  user_data = file("./user_data.sh")
}
```

## モジュール
- 他のプログラミング言語同様のモジュール化。
- ex.) HTTPサーバのモジュール化
```
$ mkdir http_server
$ cd http_server
$ touch main.tf
```

```
|--- http_server
|       |--- main2.tf  # モジュールを定義するファイル
|--- main1.tf          # モジュールを利用するファイル  
```
main2.tf
```
variable "instnce_type" {}

resource "aws_instance" "default" {
  ami = "ami-xxxxxxx"
  vpc_security_group_ids = [aws_secuirtygroup.default.id]
  instance_type = var.instnce_type
  user_data = <<EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd.service
EOF
}

resource "aws_security_group" "default" {
  name = "ec2_sg"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

output "public_dns" {
  value = aws_instance.default.public_dns
}
```

```
$ cd ../
```

main1.tf
```
module "web_server" {
  source = "./http_server"
  instance_type = "t3.micro"
}

output "public_dns" {
  value = module.web_server.public_dns
}
```
- applyはモジュール利用側のディレクトリで実行する。
  - ただし、モジュールを使用する場合、`terrafrom get` or `terraform init`を実行して、モジュールを事前に取得する必要がある。
```
$ terraform get
$ terraform apply

curl <pubic_dnsの値>
```
