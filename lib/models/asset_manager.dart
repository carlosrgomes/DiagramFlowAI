class AssetManager {
  static const String _awsRoot = 'assets/aws_icons';

  static String get ec2 => '$_awsRoot/ec2.png';
  static String get s3 => '$_awsRoot/s3.png';
  static String get rds => '$_awsRoot/rds.png';
  static String get vpc => '$_awsRoot/vpc.png';
  static String get lambda => '$_awsRoot/lambda.png';
  static String get eks => '$_awsRoot/eks.png';
  static String get route53 => '$_awsRoot/route53.png';
  static String get dynamodb => '$_awsRoot/dynamodb.png';
  static String get autoscaling => '$_awsRoot/autoscaling.png';
  static String get ebs => '$_awsRoot/ebs.png';
  static String get cloudfront => '$_awsRoot/cloudfront.png';

  static Map<String, Map<String, String>> get awsLibrary => {
    'Compute': {
      'EC2': ec2,
      'Lambda': lambda,
      'Autoscaling': autoscaling,
    },
    'Containers': {
      'EKS': eks,
    },
    'Storage': {
      'S3': s3,
      'EBS': ebs,
    },
    'Database': {
      'RDS': rds,
      'DynamoDB': dynamodb,
    },
    'Network': {
      'VPC': vpc,
      'Route53': route53,
      'CloudFront': cloudfront,
    },
  };

  static String getIconForLabel(String label) {
    final l = label.toUpperCase();
    if (l.contains('EC2')) return ec2;
    if (l.contains('RDS')) return rds;
    if (l.contains('S3')) return s3;
    if (l.contains('VPC')) return vpc;
    if (l.contains('LAMBDA')) return lambda;
    if (l.contains('EKS')) return eks;
    if (l.contains('ROUTE53')) return route53;
    if (l.contains('DYNAMODB')) return dynamodb;
    if (l.contains('AUTOSCALING')) return autoscaling;
    if (l.contains('EBS')) return ebs;
    if (l.contains('CLOUDFRONT')) return cloudfront;
    return ec2;
  }
}
