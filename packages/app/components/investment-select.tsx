import { useState } from 'react'
import { RadioGroup } from '@headlessui/react'

function CheckIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" {...props}>
      <circle cx={12} cy={12} r={12} fill="#555" opacity="1" />
      <circle cx={12} cy={12} r={11} fill="#fff" opacity="1" />
      <path
        d="M7 13l3 3 7-7"
        stroke="#000"
        strokeWidth={2}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function UncheckedIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" {...props}>
      <circle cx={12} cy={12} r={12} fill="#fff" opacity="1" />
    </svg>
  )
}

const options = [
  {
    name: 'Traditional',
    desc: 'A one-off investment',
  },
  {
    name: 'Streaming',
    desc: 'Supefluid stream',
  },
]

function InvestmentSelect(props) {
  const [selected, setSelected] = useState(options[0])

  const handleOnChange = option => {
    setSelected(option);
    if (props.onChange) {
      props.onChange(option)
    }
  }

  return (
    <div className="w-full pb-4">
      <div className="w-full mx-auto">
        <RadioGroup value={selected} onChange={handleOnChange}>
          <div className="space-x-2 flex">
            {options.map((plan) => (
              <RadioGroup.Option
                key={plan.name}
                value={plan}
                className={({ active, checked }) =>
                  `${
                    active
                      ? 'ring-2 ring-offset-2 ring-offset-white ring-purple-500'
                      : ''
                  }
                  ${
                    checked ? 'bg-white text-black' : 'bg-white selector-shading'
                  }
                    relative border border-black  px-4 py-3 cursor-pointer flex flex-grow flex-1`
                }
              >
                {({ active, checked }) => (
                  <>
                    <div className="flex items-center justify-between w-full">
                      <div className="flex items-center">
                        <div className="text-sm bg-white p-0.5">
                          <RadioGroup.Label
                            as="p"
                            className={`font-medium font-bold uppercase ${
                              checked ? 'text-black' : 'text-gray-800'
                            }`}
                          >
                            <span>{plan.name}</span>
                          </RadioGroup.Label>
                          <RadioGroup.Description
                            as="span"
                            className={`inline ${
                              checked ? 'text-black' : 'text-black'
                            }`}
                          >
                            <span>{plan.desc}</span>
                          </RadioGroup.Description>
                        </div>
                      </div>
 
                        <div className="flex-shrink-0 text-white">
                          {checked 
                          ? <CheckIcon className="w-6 h-6" />
                          : <UncheckedIcon className="w-6 h-6" />
                          }
                        </div>
                    </div>
                  </>
                )}
              </RadioGroup.Option>
            ))}
          </div>
        </RadioGroup>
      </div>
    </div>
  )
}

export default InvestmentSelect;