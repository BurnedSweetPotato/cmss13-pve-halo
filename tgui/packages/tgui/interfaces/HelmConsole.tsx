import { useBackend } from '../backend';
import { Box, Button, Flex, Icon, LabeledList, Section } from '../components';
import { Window } from '../layouts';

interface HelmData {
  error?: string;
  ship_name: string;
  x: number;
  y: number;
  max_x: number;
  max_y: number;
  sector_name: string;
  sector_desc: string;
  landable: boolean;
}

// [tooltip, font-awesome icon, dir string passed to DM's text2dir]
const GRID: [string, string, string][] = [
  ['Northwest', 'arrow-up-left', 'northwest'],
  ['North', 'arrow-up', 'north'],
  ['Northeast', 'arrow-up-right', 'northeast'],
  ['West', 'arrow-left', 'west'],
  ['', '', ''],
  ['East', 'arrow-right', 'east'],
  ['Southwest', 'arrow-down-left', 'southwest'],
  ['South', 'arrow-down', 'south'],
  ['Southeast', 'arrow-down-right', 'southeast'],
];

export const HelmConsole = () => {
  const { data, act } = useBackend<HelmData>();
  const {
    error,
    ship_name,
    x,
    y,
    max_x,
    max_y,
    sector_name,
    sector_desc,
    landable,
  } = data;

  return (
    <Window title="Helm Control" width={300} height={440}>
      <Window.Content>
        {error ? (
          <Box color="bad" p={1}>
            {error}
          </Box>
        ) : (
          <>
            <Section title={ship_name}>
              <LabeledList>
                <LabeledList.Item label="Position">
                  {x} / {y} &nbsp;
                  <Box as="span" color="label" fontSize="0.8em">
                    (max {max_x} × {max_y})
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Sector">{sector_name}</LabeledList.Item>
              </LabeledList>
              {sector_desc && (
                <Box color="label" mt={1} italic>
                  {sector_desc}
                </Box>
              )}
              {landable && (
                <Button
                  mt={1}
                  fluid
                  icon="sign-in-alt"
                  color="green"
                  onClick={() => act('land')}
                >
                  Land / Dock
                </Button>
              )}
            </Section>

            <Section title="Navigation">
              <Flex wrap="wrap" justify="center">
                {GRID.map(([tooltip, icon, dir], i) => (
                  <Flex.Item key={i} basis="33%" textAlign="center" mb={0.5}>
                    {tooltip ? (
                      <Button
                        icon={icon}
                        tooltip={tooltip}
                        width="100%"
                        onClick={() => act('move', { dir })}
                      />
                    ) : (
                      <Box pt={0.5} textAlign="center">
                        <Icon name="circle" color="label" />
                      </Box>
                    )}
                  </Flex.Item>
                ))}
              </Flex>
            </Section>

            <Section>
              <Button
                fluid
                icon="times"
                color="bad"
                onClick={() => act('disengage')}
              >
                Disengage Helm
              </Button>
            </Section>
          </>
        )}
      </Window.Content>
    </Window>
  );
};

export default HelmConsole;
