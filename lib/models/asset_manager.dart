class AssetManager {
  static const String _awsRoot = 'assets/aws_icons';

  static String get ec2 => '$_awsRoot/ec2.png';
  static String get s3 => '$_awsRoot/s3.png';
  static String get rds => '$_awsRoot/rds.png';
  static String get vpc => '$_awsRoot/vpc.png';
  static String get lambda => '$_awsRoot/lambda.png';

  static String getIconForLabel(String label) {
    final l = label.toUpperCase();
    if (l.contains('EC2')) return ec2;
    if (l.contains('RDS')) return rds;
    if (l.contains('S3')) return s3;
    if (l.contains('VPC')) return vpc;
    if (l.contains('LAMBDA')) return lambda;
    return ec2; // Fallback
  }
}
