<?php 
# by DSR! from https://github.com/xchwarze/wifi-pineapple-cloner

error_reporting(E_ALL);

if (!isset($_SERVER['argv']) && !isset($argv)) {
    echo "Please enable the register_argc_argv directive in your php.ini\n";
    exit(1);
} elseif (!isset($argv)) {
    $argv = $_SERVER['argv'];
}

if (!isset($argv[1])) {
    echo "Run with \"php opkg-parser.php [PATH] [DIFF_SEPARATOR]\"\n";
    echo "    PATH           -> path to opkg status file\n";
    echo "    DIFF_SEPARATOR -> use /n separator\n";
    exit(1);
}

function processFile($filePath)
{
    $block = [];
    $packagesData = [];

    foreach (file($filePath) as $line) {
        $clean = trim($line);

        if (empty($clean)) {
            if (count($block) > 0) {
                $packagesData[] = $block;
                $block = [];
            }
        } else {
            $parts = explode(': ', $clean);
            if (count($parts) == 2) {
                $block[ trim($parts[0]) ] = trim($parts[1]);    
            }
        }
    }

    if (count($block) > 0) {
        $packagesData[] = $block;       
    }

    return $packagesData;
}

function isValidPackage($name)
{
    $packageBlacklist = [
        // hak5 packages (based on mk6)
        'pineap',
        'aircrack-ng-hak5',
        'cc-client',
        'libwifi',
        'resetssids',
        'http_sniffer',
        'log_daemon',

        // based on hardware
        'kmod-ath',
        'kmod-ath9k',
        'kmod-ath9k-htc',
        'mt7601u-firmware',
        'uboot-envtools',
        'ubi-utils',
    ];

    // only kmod
    //return !in_array($name, $packageBlacklist) && strpos($name, 'kmod-') !== false;

    // not show kmod
    //return !in_array($name, $packageBlacklist) && strpos($name, 'kmod-') === false;

    // all
    return !in_array($name, $packageBlacklist);
}

function getResume($packagesData)
{
    $packages = [];
    $depends = [];

    // generate packages and depends array
    foreach ($packagesData as $data) {
        if (!isValidPackage($data['Package'])) {
            continue;
        }

        $packages[] = $data;
        if (isset($data['Depends'])) {
            foreach (explode(',', $data['Depends']) as $dependency) {
                $dependency = trim($dependency);
                if (!in_array($dependency, $depends)) {
                    $depends[] = $dependency;
                }
            }
        }
    }

    return [$packages, $depends];
}

function getTargetPackages($packages, $depends)
{
    $packagesData = array_filter($packages, function($data) {
        return !isset($data['Auto-Installed']);
    });

    $packageNames = array_column($packagesData, 'Package');
    $targetPackages = array_diff($packageNames, $depends);
    sort($targetPackages);

    return $targetPackages;
}

function getAutoInstalledPackages($packages)
{
    $autoInstalled = array_filter($packages, function($data) {
        return isset($data['Auto-Installed']);
    });
    
    $packageNames = array_column($autoInstalled, 'Package');
    sort($packageNames);
    
    return $packageNames;
}

function getEssentialPackages($packages)
{
    $essentials = array_filter($packages, function($data) {
        return isset($data['Essential']);
    });
    
    $packageNames = array_column($essentials, 'Package');
    sort($packageNames);
    
    return $packageNames;
}

function console($text, $lineBreaks = 1)
{
    echo $text;
    echo str_repeat("\n", $lineBreaks);
}


console("opkg status parser - by DSR!");
console("---------------------------------------", 2);
$printSep   = (isset($argv[2]) && filter_var($argv[2], FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE)) ? "\n" : ' ';
$statusFile = $argv[1];

if (!file_exists($statusFile)) {
    console("[!!!] File not found: $statusFile");
    return 0;
}


$packagesData = processFile($statusFile);
list($packages, $depends) = getResume($packagesData);

$targetPackages = getTargetPackages($packages, $depends);
$essentials = getEssentialPackages($packages);
$autoInstalled = getAutoInstalledPackages($packages);

// print.....
console("======== Packages (" . count($targetPackages) . ") ========");
echo implode($printSep, $targetPackages);
console("", 3);

console("======== Essential Packages (" . count($essentials) . ") ========");
echo implode($printSep, $essentials);
console("", 3);

console("======== Auto-Installed Packages (" . count($autoInstalled) . ") ========");
echo implode($printSep, $autoInstalled);
console("", 3);
