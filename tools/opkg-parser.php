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

function processFile($filePath, $showEssentials, $showDependencies)
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

    return cleanInstallData($packagesData, $showEssentials, $showDependencies);
}

function cleanInstallData($output, $showEssentials, $showDependencies)
{
    $packages = [];
    $depends = [];

    // generate packages and depends array
    foreach ($output as $data) {
        if ( 
            !isset($data['Auto-Installed']) && 
            isValidPackage($data['Package']) 
        ) {
            if (
                !isset($data['Essential']) || 
                (
                    isset($data['Essential']) && $showEssentials
                )
            ) {
                $packages[] = $data['Package'];

                if (isset($data['Depends'])) {
                    foreach (explode(',', $data['Depends']) as $dependency) {
                        $dependency = trim($dependency);
                        if (!in_array($dependency, $depends)) {
                            $depends[] = $dependency;
                        }
                    }
                }
            }
        }
    }

    // show all installed packages
    if ($showDependencies) {
        sort($packages);
        return $packages;
    }

    // show only target packages
    $targetPackages = [];
    foreach ($packages as $package) {
        if (!in_array($package, $depends)) {
            $targetPackages[] = $package;
        }
    }

    //var_dump($depends);
    sort($targetPackages);
    return $targetPackages;
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



echo "\nopkg status parser - by DSR!";
echo "\n---------------------------------------\n\n";
$printSep   = (isset($argv[2]) && filter_var($argv[2], FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE)) ? "\n" : ' ';
$statusFile = $argv[1];

if (!file_exists($statusFile)) {
    echo "[!!!] File not found: \"($statusFile)\"\n";
    return 0;
}


$statusData = processFile($statusFile, false, false);

echo "======== Packages (" . count($statusData) . ") ========\n";
echo implode($printSep, $statusData);
echo "\n\n\n";


$statusDataEssentials = processFile($statusFile, true, false);
$essentialPackages = [];
foreach ($statusDataEssentials as $key) {
    if (!in_array($key, $statusData)) {
        $essentialPackages[] = $key;
    }
}

echo "======== Essentials Packages (" . count($essentialPackages) . ") ========\n";
echo implode($printSep, $essentialPackages);
echo "\n";
